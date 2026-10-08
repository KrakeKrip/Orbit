import { describe, expect, it } from "vitest";
import { renderToStaticMarkup } from "react-dom/server";
import Home from "@/app/page";

describe("стартовая страница Orbit", () => {
  it("рендерится без ошибок, с доступным заголовком и описанием", () => {
    const html = renderToStaticMarkup(<Home />);

    expect(html).toContain("<h1");
    expect(html).toContain("Orbit");
    expect(html).toContain("Персональный менеджер задач");
  });
});
