import type { ReactNode } from "react";
import { AppShell } from "@/components/orbit/app-shell";
import { requireUserOrRedirect } from "@/server/auth/session";

export default async function WorkspaceLayout({
  children,
}: {
  children: ReactNode;
}) {
  // Server-side guard для всех workspace маршрутов. Это навигационный
  // redirect, а не замена проверке каждого server entry point/service:
  // API и будущие services используют requireUser() самостоятельно.
  await requireUserOrRedirect();
  return <AppShell>{children}</AppShell>;
}
