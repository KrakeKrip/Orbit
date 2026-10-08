"use client";

import { useSyncExternalStore } from "react";
import { useTheme } from "next-themes";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { ru } from "@/lib/i18n/ru";

const THEME_OPTIONS = [
  { value: "system", label: ru.settings.theme.options.system },
  { value: "light", label: ru.settings.theme.options.light },
  { value: "dark", label: ru.settings.theme.options.dark },
] as const;

const noopSubscribe = () => () => {};
const getClientSnapshot = () => true;
const getServerSnapshot = () => false;

export function ThemeSelect() {
  const { theme, setTheme } = useTheme();
  // false на сервере и во время гидратации, true после mount: значение Select
  // остаётся согласованным с серверным HTML, сохранённая тема подставляется
  // без рассинхрона гидратации.
  const mounted = useSyncExternalStore(
    noopSubscribe,
    getClientSnapshot,
    getServerSnapshot,
  );

  const value = mounted ? (theme ?? "system") : "system";

  return (
    <Select value={value} onValueChange={setTheme}>
      <SelectTrigger id="theme-select" className="w-full max-w-56">
        <SelectValue />
      </SelectTrigger>
      <SelectContent>
        {THEME_OPTIONS.map((option) => (
          <SelectItem key={option.value} value={option.value}>
            {option.label}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}
