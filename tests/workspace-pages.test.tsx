import { describe, expect, it } from "vitest";
import { renderToStaticMarkup } from "react-dom/server";
import TodayPage from "@/app/(workspace)/today/page";
import InboxPage from "@/app/(workspace)/inbox/page";
import UpcomingPage from "@/app/(workspace)/upcoming/page";
import { ProjectsView } from "@/components/orbit/projects-view";
import type { ProjectDTO } from "@/lib/projects";

// /projects — реальный server-driven экран (actor + БД), поэтому unit-уровень
// покрывает клиентский ProjectsView (список/empty/escaping); полный flow —
// HTTP integration и browser E2E. Остальные экраны — placeholders.
const screens = [
  { name: "Сегодня", page: TodayPage },
  { name: "Входящие", page: InboxPage },
  { name: "Предстоящее", page: UpcomingPage },
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

function project(id: string, name: string, archived = false): ProjectDTO {
  const timestamp = new Date("2026-01-01T00:00:00.000Z").toISOString();
  return {
    id,
    name,
    archivedAt: archived ? timestamp : null,
    createdAt: timestamp,
    updatedAt: timestamp,
  };
}

describe("ProjectsView (unit render)", () => {
  it("пустой список: tabs, create form и honest empty state активных", () => {
    const html = renderToStaticMarkup(
      <ProjectsView initialActive={[]} initialArchived={[]} actorId="user-1" />,
    );

    expect(html).toContain("Активные");
    expect(html).toContain("Архив");
    expect(html).toContain("Название проекта");
    expect(html).toContain("Создать проект");
    expect(html).toContain("Проектов пока нет");
    expect(html).toContain("Создайте первый проект");
  });

  it("имена проектов рендерятся текстом с экранированием markup", () => {
    const html = renderToStaticMarkup(
      <ProjectsView
        initialActive={[
          project("11111111-1111-4111-8111-111111111111", "<b>Учёба</b>"),
          project(
            "22222222-2222-4222-8222-222222222222",
            "🦄🦄 Очень длинное название проекта, которое занимает больше одной строки и не должно ломать вёрстку",
          ),
        ]}
        initialArchived={[
          project("33333333-3333-4333-8333-333333333333", "Архивный", true),
        ]}
        actorId="user-1"
      />,
    );

    // markup — экранированный текст, не HTML-тег.
    expect(html).toContain("&lt;b&gt;Учёба&lt;/b&gt;");
    expect(html).not.toContain("<b>Учёба</b>");
    expect(html).toContain("🦄🦄 Очень длинное название");
    expect(html).toContain("break-words");
    // Действия строк доступны; архивный проект не смешан с активным списком.
    expect(html).toContain("Архивировать");
    expect(html).toContain("Переименовать");
    expect(html).not.toContain(">Архивный<");
  });
});
