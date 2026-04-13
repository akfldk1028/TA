/**
 * TTS Server — Express HTTP API
 *
 * Endpoints:
 *   GET  /health                → { status, providers }
 *   POST /api/generate          → Sync: TTSRequest → TTSResponse
 *   POST /api/generate/async    → Async: → { jobId }
 *   GET  /api/status/:jobId     → Job status + result
 *   GET  /api/voices            → All voices
 *   GET  /api/voices/:provider  → Provider-specific voices
 */

import express from "express";
import { randomUUID } from "crypto";
import type { TTSClient } from "./tts-client";
import type { Job, TTSRequest } from "./types";
import { logger } from "./logger";

export function createServer(client: TTSClient) {
  const app = express();
  app.use(express.json({ limit: "10mb" }));

  const jobs = new Map<string, Job>();

  // ─── Health ──────────────────────────────────────────

  app.get("/health", (_req, res) => {
    res.json({
      status: "ok",
      providers: client.getProviderNames(),
      timestamp: new Date().toISOString(),
    });
  });

  // ─── Sync generate ──────────────────────────────────

  app.post("/api/generate", async (req, res) => {
    const body = req.body as TTSRequest;

    if (!body.text?.trim()) {
      res.status(400).json({ error: "text is required" });
      return;
    }

    try {
      logger.info({ text: body.text.substring(0, 60), provider: body.provider }, "Sync TTS request");
      const result = await client.generate(body);
      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      logger.error({ error: message }, "Sync TTS failed");
      res.status(500).json({ error: message });
    }
  });

  // ─── Async generate ─────────────────────────────────

  app.post("/api/generate/async", (req, res) => {
    const body = req.body as TTSRequest;

    if (!body.text?.trim()) {
      res.status(400).json({ error: "text is required" });
      return;
    }

    const jobId = randomUUID();
    const job: Job = { id: jobId, status: "queued", createdAt: Date.now(), request: body };
    jobs.set(jobId, job);

    logger.info({ jobId, text: body.text.substring(0, 60) }, "Async TTS job queued");

    (async () => {
      job.status = "processing";
      try {
        job.result = await client.generate(body);
        job.status = "completed";
        job.completedAt = Date.now();
        logger.info({ jobId, elapsed: job.completedAt - job.createdAt }, "Async TTS completed");
      } catch (error) {
        job.status = "failed";
        job.completedAt = Date.now();
        job.error = error instanceof Error ? error.message : "Unknown error";
        logger.error({ jobId, error: job.error }, "Async TTS failed");
      }
    })();

    res.status(202).json({ jobId, status: "queued" });
  });

  // ─── Job status ──────────────────────────────────────

  app.get("/api/status/:jobId", (req, res) => {
    const job = jobs.get(req.params.jobId);
    if (!job) {
      res.status(404).json({ error: "Job not found" });
      return;
    }

    const response: Record<string, unknown> = {
      id: job.id,
      status: job.status,
      createdAt: job.createdAt,
    };
    if (job.completedAt) {
      response.completedAt = job.completedAt;
      response.elapsedMs = job.completedAt - job.createdAt;
    }
    if (job.result) response.result = job.result;
    if (job.error) response.error = job.error;

    res.json(response);
  });

  // ─── Voices ──────────────────────────────────────────

  app.get("/api/voices", async (_req, res) => {
    try {
      const voices = await client.listVoices(undefined, _req.query.language as string);
      res.json(voices);
    } catch (error) {
      res.status(500).json({ error: "Failed to list voices" });
    }
  });

  app.get("/api/voices/:provider", async (req, res) => {
    try {
      const voices = await client.listVoices(req.params.provider, req.query.language as string);
      res.json(voices);
    } catch (error) {
      res.status(500).json({ error: "Failed to list voices" });
    }
  });

  return app;
}
