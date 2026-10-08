import { ThemeSelect } from "@/components/orbit/theme-select";
import { PageHeader } from "@/components/orbit/page-header";
import { ru } from "@/lib/i18n/ru";

export default function SettingsPage() {
  return (
    <div>
      <PageHeader title={ru.settings.title} description={ru.settings.description} />
      <section className="rounded-xl border bg-card p-4">
        <label
          htmlFor="theme-select"
          className="block text-sm font-medium leading-6"
        >
          {ru.settings.theme.label}
        </label>
        <p className="mt-1 text-sm leading-5 text-muted-foreground">
          {ru.settings.theme.hint}
        </p>
        <div className="mt-3">
          <ThemeSelect />
        </div>
      </section>
    </div>
  );
}
