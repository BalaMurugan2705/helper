import type { IncomingMessage, ServerResponse } from "node:http";
import { timingSafeEqual } from "node:crypto";
import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { z } from "zod";

// Collections under users/{uid}/ that the Flutter app uses.
const COLLECTIONS = [
  "cleaning_tasks",
  "shopping_items",
  "budget_categories",
  "health_habits",
  "expenses",
  "wish_list",
  "food_entries",
  "html_files",
  "daily_logs",
] as const;

// Fields the app stores as Firestore Timestamps; accepted as ISO strings here.
const TIMESTAMP_FIELDS = new Set(["date", "createdAt", "lastDoneDate", "addedDate"]);

function db() {
  if (!getApps().length) {
    initializeApp({
      credential: cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT!)),
    });
  }
  return getFirestore();
}

function col(name: string) {
  return db().collection("users").doc(process.env.FIREBASE_UID!).collection(name);
}

function toPlain(value: unknown): unknown {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(toPlain);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, toPlain(v)]));
  }
  return value;
}

function toFirestore(data: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(data).map(([k, v]) => [
      k,
      TIMESTAMP_FIELDS.has(k) && typeof v === "string"
        ? Timestamp.fromDate(new Date(v))
        : v,
    ]),
  );
}

const text = (data: unknown) => ({
  content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }],
});

const collection = z.enum(COLLECTIONS).describe("Collection name");

function buildServer() {
  const server = new McpServer({ name: "helper-app", version: "1.0.0" });

  server.tool(
    "list_collections",
    "List the collections available in the Helper app.",
    async () => text(COLLECTIONS),
  );

  server.tool(
    "list_documents",
    "List documents in a collection. daily_logs ids are yyyy-MM-dd dates.",
    {
      collection,
      limit: z.number().int().min(1).max(200).default(50),
      orderBy: z.string().optional().describe("Field to sort by, e.g. 'date'"),
      descending: z.boolean().default(true),
    },
    async ({ collection: name, limit, orderBy, descending }) => {
      let q: FirebaseFirestore.Query = col(name);
      if (orderBy) q = q.orderBy(orderBy, descending ? "desc" : "asc");
      const snap = await q.limit(limit).get();
      return text(snap.docs.map((d) => ({ id: d.id, ...(toPlain(d.data()) as object) })));
    },
  );

  server.tool(
    "get_document",
    "Get one document by id.",
    { collection, id: z.string() },
    async ({ collection: name, id }) => {
      const d = await col(name).doc(id).get();
      return text(d.exists ? { id: d.id, ...(toPlain(d.data()) as object) } : null);
    },
  );

  server.tool(
    "add_document",
    "Create a document (auto id, or pass id e.g. '2026-10-05' for daily_logs). " +
      "Date fields (date, createdAt, lastDoneDate, addedDate) take ISO strings. " +
      "Call list_documents first to copy the field shape of existing entries.",
    {
      collection,
      id: z.string().optional(),
      data: z.record(z.unknown()),
    },
    async ({ collection: name, id, data }) => {
      const payload = toFirestore(data);
      if (id) {
        await col(name).doc(id).set(payload, { merge: true });
        return text({ id });
      }
      const ref = await col(name).add(payload);
      return text({ id: ref.id });
    },
  );

  server.tool(
    "update_document",
    "Merge fields into an existing document.",
    { collection, id: z.string(), data: z.record(z.unknown()) },
    async ({ collection: name, id, data }) => {
      await col(name).doc(id).update(toFirestore(data));
      return text({ id, updated: true });
    },
  );

  server.tool(
    "delete_document",
    "Permanently delete a document. Confirm with the user first.",
    { collection, id: z.string() },
    async ({ collection: name, id }) => {
      await col(name).doc(id).delete();
      return text({ id, deleted: true });
    },
  );

  // ─── Food tracker (users/{uid}/food_entries) ───────────────────────
  const mealType = z.enum(["breakfast", "lunch", "dinner", "snack"]);

  server.tool(
    "add_food_entry",
    "Log a food item in the Food Tracker. Shows up in the app and rolls into the Daily Monitor " +
      "calorie/protein totals. Estimate macros if the user doesn't give them.",
    {
      name: z.string().describe("Food name, e.g. 'Idli x3'"),
      mealType: mealType.default("snack"),
      calories: z.number().min(0).describe("kcal"),
      protein: z.number().min(0).default(0).describe("grams"),
      carbs: z.number().min(0).default(0).describe("grams"),
      fat: z.number().min(0).default(0).describe("grams"),
      date: z
        .string()
        .optional()
        .describe("ISO date-time when eaten (include timezone offset, e.g. 2026-10-09T08:30:00+05:30). Defaults to now."),
      note: z.string().default(""),
    },
    async ({ date, ...rest }) => {
      const when = date ? new Date(date) : new Date();
      if (isNaN(when.getTime())) throw new Error(`Invalid date: ${date}`);
      const ref = await col("food_entries").add({ ...rest, date: Timestamp.fromDate(when) });
      return text({ id: ref.id, ...rest, date: when.toISOString() });
    },
  );

  server.tool(
    "list_food_entries",
    "List food entries between two instants (start inclusive, end exclusive) with totals. " +
      "For one day pass that day's local midnight and the next midnight, with timezone offset.",
    {
      start: z.string().describe("ISO date-time, e.g. 2026-10-09T00:00:00+05:30"),
      end: z.string().describe("ISO date-time, exclusive"),
    },
    async ({ start, end }) => {
      const s = new Date(start);
      const e = new Date(end);
      if (isNaN(s.getTime()) || isNaN(e.getTime())) throw new Error("Invalid start/end date");
      const snap = await col("food_entries")
        .where("date", ">=", Timestamp.fromDate(s))
        .where("date", "<", Timestamp.fromDate(e))
        .orderBy("date", "asc")
        .get();
      const entries = snap.docs.map((d) => ({ id: d.id, ...(toPlain(d.data()) as Record<string, unknown>) }));
      const sum = (k: string) =>
        entries.reduce((t, x) => t + (Number((x as Record<string, unknown>)[k]) || 0), 0);
      return text({
        totals: { calories: sum("calories"), protein: sum("protein"), carbs: sum("carbs"), fat: sum("fat") },
        entries,
      });
    },
  );

  return server;
}

function tokenOk(provided: string | null) {
  const expected = process.env.MCP_TOKEN;
  if (!expected || !provided) return false;
  const a = Buffer.from(provided);
  const b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
}

async function readBody(req: IncomingMessage) {
  const chunks: Buffer[] = [];
  for await (const c of req) chunks.push(c as Buffer);
  const raw = Buffer.concat(chunks).toString();
  return raw ? JSON.parse(raw) : undefined;
}

export default async function handler(req: IncomingMessage, res: ServerResponse) {
  const url = new URL(req.url ?? "/", "http://localhost");
  if (!tokenOk(url.searchParams.get("token"))) {
    res.statusCode = 401;
    res.end("Unauthorized");
    return;
  }
  if (req.method !== "POST") {
    res.statusCode = 405;
    res.setHeader("Allow", "POST");
    res.end("Method not allowed");
    return;
  }

  // Stateless: a fresh server + transport per request.
  const server = buildServer();
  const transport = new StreamableHTTPServerTransport({
    sessionIdGenerator: undefined,
    enableJsonResponse: true,
  });
  res.on("close", () => {
    transport.close();
    server.close();
  });
  await server.connect(transport);
  await transport.handleRequest(req, res, await readBody(req));
}
