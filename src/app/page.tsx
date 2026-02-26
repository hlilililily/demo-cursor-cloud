"use client";

import { useState } from "react";
import { Counter } from "@/components/Counter";

export default function Home() {
  const [greeting, setGreeting] = useState("");
  const [name, setName] = useState("");

  const handleGreet = () => {
    if (!name.trim()) return;
    setGreeting(`Hello, ${name.trim()}! Welcome to Cursor Cloud.`);
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-8 bg-gradient-to-b from-slate-900 to-slate-800 p-8 text-white">
      <h1 className="text-4xl font-bold tracking-tight">Demo Cursor Cloud</h1>
      <p className="text-lg text-slate-300">
        A simple demo for testing cursor cloud agents
      </p>

      <div className="flex w-full max-w-md flex-col gap-4 rounded-xl bg-slate-700/50 p-6">
        <label htmlFor="name-input" className="text-sm font-medium text-slate-300">
          Enter your name
        </label>
        <div className="flex gap-2">
          <input
            id="name-input"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && handleGreet()}
            placeholder="Your name..."
            className="flex-1 rounded-lg border border-slate-600 bg-slate-800 px-4 py-2 text-white placeholder-slate-400 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
          />
          <button
            onClick={handleGreet}
            className="rounded-lg bg-blue-600 px-6 py-2 font-medium text-white transition-colors hover:bg-blue-500 disabled:opacity-50"
            disabled={!name.trim()}
          >
            Greet
          </button>
        </div>
        {greeting && (
          <p data-testid="greeting" className="mt-2 text-center text-xl font-semibold text-green-400">
            {greeting}
          </p>
        )}
      </div>

      <Counter />
    </main>
  );
}
