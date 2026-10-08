"use client";

import { useRef, useState } from "react";
import { useTheme } from "next-themes";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { SettingsTheme } from "@/lib/settings";
import { ru } from "@/lib/i18n/ru";

const THEME_OPTIONS = [
  { value: "system", label: ru.settings.theme.options.system },
  { value: "light", label: ru.settings.theme.options.light },
  { value: "dark", label: ru.settings.theme.options.dark },
] as const;

async function patchSettingsTheme(theme: SettingsTheme): Promise<boolean> {
  const response = await fetch("/api/v1/settings", {
    method: "PATCH",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ theme }),
  });
  return response.ok;
}

/**
 * Выбор темы с сохранением в аккаунте: выбор применяется сразу (preview и
 * визуальный cache orbit-theme) и отправляется PATCH; подтверждённым
 * значением считается только ответ сервера. Pending блокирует повторные
 * собственные сохранения; при ошибке тема откатывается к последней
 * подтверждённой account theme и видима ошибка. Значение Select берётся из
 * серверного состояния аккаунта, а не из localStorage: устаревший cache
 * другого actor не отображается и не сохраняется.
 */
export function AccountThemeSelect({
  confirmedTheme,
}: {
  confirmedTheme: SettingsTheme;
}) {
  const { setTheme } = useTheme();
  const [confirmed, setConfirmed] = useState<SettingsTheme>(confirmedTheme);
  const [pendingTheme, setPendingTheme] = useState<SettingsTheme | null>(null);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState(false);
  const inFlight = useRef(false);

  async function handleChange(next: string): Promise<void> {
    if (inFlight.current) {
      return;
    }
    const theme = next as SettingsTheme;
    setTheme(theme);
    setError(false);
    setSaved(false);
    setPendingTheme(theme);
    inFlight.current = true;
    try {
      if (await patchSettingsTheme(theme)) {
        setConfirmed(theme);
        setSaved(true);
      } else {
        setTheme(confirmed);
        setError(true);
      }
    } catch {
      setTheme(confirmed);
      setError(true);
    } finally {
      setPendingTheme(null);
      inFlight.current = false;
    }
  }

  return (
    <div aria-busy={pendingTheme !== null}>
      <Select
        value={pendingTheme ?? confirmed}
        onValueChange={(value) => void handleChange(value)}
      >
        {/* min-h-11 перекрывает data-[size]:h-8: фактическая область нажатия >= 44px */}
        <SelectTrigger id="theme-select" className="min-h-11 w-full max-w-56">
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {THEME_OPTIONS.map((option) => (
            <SelectItem
              key={option.value}
              value={option.value}
              className="min-h-11"
            >
              {option.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
      <p aria-live="polite" className="mt-2 text-sm leading-5">
        {pendingTheme !== null ? (
          <span className="text-muted-foreground">{ru.settings.theme.saving}</span>
        ) : error ? (
          <span role="alert" className="text-destructive">
            {ru.settings.theme.saveError}
          </span>
        ) : saved ? (
          <span className="text-muted-foreground">{ru.settings.theme.saved}</span>
        ) : null}
      </p>
    </div>
  );
}
