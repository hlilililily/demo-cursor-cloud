import { render, screen, fireEvent } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import Home from "@/app/page";

describe("Home page", () => {
  it("renders the heading", () => {
    render(<Home />);
    expect(screen.getByText("Demo Cursor Cloud")).toBeInTheDocument();
  });

  it("greet button is disabled when name is empty", () => {
    render(<Home />);
    expect(screen.getByText("Greet")).toBeDisabled();
  });

  it("displays a greeting when name is entered and Greet is clicked", () => {
    render(<Home />);
    fireEvent.change(screen.getByPlaceholderText("Your name..."), {
      target: { value: "World" },
    });
    fireEvent.click(screen.getByText("Greet"));
    expect(screen.getByTestId("greeting")).toHaveTextContent(
      "Hello, World! Welcome to Cursor Cloud."
    );
  });
});
