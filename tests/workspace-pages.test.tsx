import { describe, expect, it } from "vitest";
import { renderToStaticMarkup } from "react-dom/server";
import TodayPage from "@/app/(workspace)/today/page";
import InboxPage from "@/app/(workspace)/inbox/page";
import UpcomingPage from "@/app/(workspace)/upcoming/page";
import ProjectsPage from "@/app/(workspace)/projects/page";

const screens = [
  { name: "Сегодня", page: TodayPage },
  { name: "Входящие", page: InboxPage },
  { name: "Предстоящее", page: UpcomingPage },
  { name: "Проекты", page: ProjectsPage },
] as const;

describe("экраны рабочей области", () => {
  it.each(screens)(
    "$name рендерится с одним h1 и пояснением о подключении данных",
    ({ name, page: Screen }) => {
      const html = renderToStaticMarkup(<Screen />);

      expect(html.match(/<h1/g)?.length).toBe(1);
      expect(html).toContain(name);
      expect(html).toContain("будут подключены на следующих этапах");
    },
  );
});
