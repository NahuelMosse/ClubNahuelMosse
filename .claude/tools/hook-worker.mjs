// Runs one hook inside a worker thread of hook-dispatch.mjs: gives it the call it would have read from
// its own stdin and imports it. The hook's `process.exit` ends this thread with its code, and what it
// writes to stdout and stderr is collected by the dispatcher.
import { workerData } from 'node:worker_threads';
import { feedStdin } from './card.mjs';

feedStdin(workerData.raw);
await import(workerData.hook);
