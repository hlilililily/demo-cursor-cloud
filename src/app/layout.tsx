import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Demo Cursor Cloud",
  description: "A simple demo for testing cursor cloud agents",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
