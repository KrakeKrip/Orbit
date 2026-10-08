import { TasksView } from "@/components/orbit/tasks-view";
import { PageHeader } from "@/components/orbit/page-header";
import { ru } from "@/lib/i18n/ru";
import { requireUserOrRedirect } from "@/server/auth/session";
import { listInboxTasks } from "@/server/tasks/service";
import { toTaskDTO } from "@/lib/tasks";

export default async function InboxPage() {
  // Actor и начальные списки только из проверенной сессии; открытые и
  // завершённые Inbox-задачи загружаются независимо.
  const user = await requireUserOrRedirect();
  const [open, completed] = await Promise.all([
    listInboxTasks(user.id, "open"),
    listInboxTasks(user.id, "completed"),
  ]);

  return (
    <div>
      <PageHeader
        title={ru.pages.inbox.title}
        description={ru.pages.inbox.description}
      />
      <TasksView
        initialOpen={open.map(toTaskDTO)}
        initialCompleted={completed.map(toTaskDTO)}
        actorId={user.id}
      />
    </div>
  );
}
