"use client";

import { useState } from "react";

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div className="flex flex-col items-center gap-4 rounded-xl bg-slate-700/50 p-6">
      <p className="text-sm font-medium text-slate-300">Interactive Counter</p>
      <p data-testid="count" className="text-5xl font-bold tabular-nums">
        {count}
      </p>
      <div className="flex gap-3">
        <button
          onClick={() => setCount((c) => c - 1)}
          className="rounded-lg bg-red-600 px-4 py-2 font-medium text-white transition-colors hover:bg-red-500"
          aria-label="Decrement"
        >
          -1
        </button>
        <button
          onClick={() => setCount(0)}
          className="rounded-lg bg-slate-600 px-4 py-2 font-medium text-white transition-colors hover:bg-slate-500"
          aria-label="Reset"
        >
          Reset
        </button>
        <button
          onClick={() => setCount((c) => c + 1)}
          className="rounded-lg bg-green-600 px-4 py-2 font-medium text-white transition-colors hover:bg-green-500"
          aria-label="Increment"
        >
          +1
        </button>
      </div>
    </div>
  );
}
