import { CalendarRange } from "lucide-react";
import { EmptyView } from "@/components/orbit/empty-view";
import { PageHeader } from "@/components/orbit/page-header";
import { ru } from "@/lib/i18n/ru";

export default function UpcomingPage() {
  const page = ru.pages.upcoming;

  return (
    <div>
      <PageHeader title={page.title} description={page.description} />
      <EmptyView
        icon={CalendarRange}
        title={page.empty.title}
        description={page.empty.description}
      />
    </div>
  );
}
