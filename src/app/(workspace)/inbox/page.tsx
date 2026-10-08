import { Inbox } from "lucide-react";
import { EmptyView } from "@/components/orbit/empty-view";
import { PageHeader } from "@/components/orbit/page-header";
import { ru } from "@/lib/i18n/ru";

export default function InboxPage() {
  const page = ru.pages.inbox;

  return (
    <div>
      <PageHeader title={page.title} description={page.description} />
      <EmptyView
        icon={Inbox}
        title={page.empty.title}
        description={page.empty.description}
      />
    </div>
  );
}
