import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type MouseEvent,
} from "react";

// ─── Icons (inline SVG) ─────────────────────────────────────────────────────
function ClearIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <line x1="18" y1="6" x2="6" y2="18" />
      <line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  );
}

function PlayIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M8 5v14l11-7L8 5z" />
    </svg>
  );
}

function PauseIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
    </svg>
  );
}

// ─── Keyboard layout (Arabic, right-to-left visual order) ───────────────────
const ROW_1 = ["ا", "ب", "ت", "ث", "ج", "ح", "خ", "د", "ذ", "J"];
const ROW_2 = ["ز", "س", "ش", "ص", "ض", "ط", "ظ", "ع", "غ", "ف"];
const ROW_3 = ["ق", "ك", "ل", "م", "ن", "ه", "و", "ي", "ة", "ئ"];

const AUTOPLAY_DELAY_MS = 700;

export type KeyboardProps = {
  onKeyPress?: (key: string) => void;
  onClear?: () => void;
  onAutoPlay?: () => void;
  onPause?: () => void;
};

export default function Keyboard({
  onKeyPress,
  onClear,
  onAutoPlay,
  onPause,
}: KeyboardProps) {
  const orderedKeys = useMemo(() => [...ROW_1, ...ROW_2, ...ROW_3], []);
  const [isPlaying, setIsPlaying] = useState(false);
  const [selectedKeys, setSelectedKeys] = useState<string[]>([]);

  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const playIndexRef = useRef(0);

  const triggerKey = useCallback(
    (key: string) => {
      if (!key) return;
      setSelectedKeys((prev) => [...prev, key]);
      onKeyPress?.(key);
    },
    [onKeyPress],
  );

  const clearAutoplayInterval = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
  }, []);

  const stopAutoplay = useCallback(() => {
    setIsPlaying(false);
    clearAutoplayInterval();
  }, [clearAutoplayInterval]);

  const handleKeyClick = useCallback(
    (e: MouseEvent<HTMLButtonElement>) => {
      const key = e.currentTarget.dataset.key ?? "";
      triggerKey(key);
    },
    [triggerKey],
  );

  const handleAutoPlay = useCallback(() => {
    onAutoPlay?.();

    if (isPlaying) {
      return;
    }

    if (playIndexRef.current >= orderedKeys.length) {
      playIndexRef.current = 0;
    }

    setIsPlaying(true);
  }, [isPlaying, onAutoPlay, orderedKeys.length]);

  const handlePause = useCallback(() => {
    onPause?.();
    stopAutoplay();
  }, [onPause, stopAutoplay]);

  const handleClear = useCallback(() => {
    setSelectedKeys((prev) => prev.slice(0, -1));
    onClear?.();
  }, [onClear]);

  useEffect(() => {
    if (!isPlaying) {
      return;
    }

    intervalRef.current = setInterval(() => {
      const currentIndex = playIndexRef.current;

      if (currentIndex >= orderedKeys.length) {
        stopAutoplay();
        return;
      }

      triggerKey(orderedKeys[currentIndex]);

      const nextIndex = currentIndex + 1;
      playIndexRef.current = nextIndex;

      if (nextIndex >= orderedKeys.length) {
        stopAutoplay();
      }
    }, AUTOPLAY_DELAY_MS);

    return clearAutoplayInterval;
  }, [clearAutoplayInterval, isPlaying, orderedKeys, stopAutoplay, triggerKey]);

  return (
    <div className="w-full rounded-3xl bg-white p-8 shadow-xl">
      <h2 className="mb-8 text-center text-2xl font-bold text-indigo-700">
        لوحة المفاتيح
      </h2>

      <div className="flex flex-col gap-4">
        <div
          className="flex w-full justify-center gap-2"
          style={{ direction: "rtl" }}
        >
          {ROW_1.map((char) => (
            <button
              key={char}
              type="button"
              data-key={char}
              onClick={handleKeyClick}
              className="flex h-16 min-w-16 items-center justify-center rounded-lg bg-[#DBE9FD] font-bold text-[#38578C] shadow-md transition-transform hover:scale-105 active:scale-95"
            >
              {char}
            </button>
          ))}
        </div>

        <div className="flex justify-center gap-2" style={{ direction: "rtl" }}>
          {ROW_2.map((char) => (
            <button
              key={char}
              type="button"
              data-key={char}
              onClick={handleKeyClick}
              className="flex h-16 min-w-16 items-center justify-center rounded-lg bg-emerald-100 font-bold text-emerald-800 shadow-md transition-transform hover:scale-105 active:scale-95"
            >
              {char}
            </button>
          ))}
        </div>

        <div className="flex justify-center gap-2" style={{ direction: "rtl" }}>
          {ROW_3.map((char) => (
            <button
              key={char}
              type="button"
              data-key={char}
              onClick={handleKeyClick}
              className="flex h-16 min-w-16 items-center justify-center rounded-lg bg-fuchsia-100 font-bold text-fuchsia-800 shadow-md transition-transform hover:scale-105 active:scale-95"
            >
              {char}
            </button>
          ))}
        </div>

        <div className="mt-6 flex justify-center gap-4" dir="rtl">
          <button
            type="button"
            onClick={handleClear}
            className="flex items-center gap-2 rounded-full border-2 border-indigo-700 bg-white px-6 py-3 font-bold text-indigo-700 shadow-md transition-transform hover:scale-105 active:scale-95"
          >
            <span className="flex h-8 w-8 items-center justify-center rounded">
              <ClearIcon className="h-5 w-5" />
            </span>
            مسح
          </button>
          {isPlaying ? (
            <button
              type="button"
              onClick={handlePause}
              className="flex items-center gap-2 rounded-full bg-fuchsia-100 px-6 py-3 font-bold text-fuchsia-800 shadow-md transition-transform hover:scale-105 active:scale-95"
            >
              <span className="flex h-8 w-8 items-center justify-center rounded">
                <PauseIcon className="h-5 w-5" />
              </span>
              ايقاف مؤقت
            </button>
          ) : (
            <button
              type="button"
              onClick={handleAutoPlay}
              className="flex items-center gap-2 rounded-full bg-indigo-100 px-6 py-3 font-bold text-indigo-700 shadow-md transition-transform hover:scale-105 active:scale-95"
            >
              <span className="flex h-8 w-8 items-center justify-center rounded">
                <PlayIcon className="h-5 w-5" />
              </span>
              تشغيل تلقائي
            </button>
          )}
        </div>

        {selectedKeys.length > 0 && (
          <p
            className="mt-4 text-center text-sm font-medium text-slate-600"
            dir="rtl"
          >
            الأحرف المختارة: {selectedKeys.join(" ")}
          </p>
        )}
      </div>
    </div>
  );
}
