import { render, screen, fireEvent } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { Counter } from "@/components/Counter";

describe("Counter", () => {
  it("renders with initial count of 0", () => {
    render(<Counter />);
    expect(screen.getByTestId("count")).toHaveTextContent("0");
  });

  it("increments the count when +1 is clicked", () => {
    render(<Counter />);
    fireEvent.click(screen.getByLabelText("Increment"));
    expect(screen.getByTestId("count")).toHaveTextContent("1");
  });

  it("decrements the count when -1 is clicked", () => {
    render(<Counter />);
    fireEvent.click(screen.getByLabelText("Decrement"));
    expect(screen.getByTestId("count")).toHaveTextContent("-1");
  });

  it("resets the count to 0", () => {
    render(<Counter />);
    fireEvent.click(screen.getByLabelText("Increment"));
    fireEvent.click(screen.getByLabelText("Increment"));
    fireEvent.click(screen.getByLabelText("Reset"));
    expect(screen.getByTestId("count")).toHaveTextContent("0");
  });
});
