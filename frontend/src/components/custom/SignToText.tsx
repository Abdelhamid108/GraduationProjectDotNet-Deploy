import * as signalR from "@microsoft/signalr";
import { useEffect, useRef, useState } from "react";

import { finalizeSentence } from "@/Api/APICalls";
const CameraIcon = ({ className = "h-8 w-8" }: { className?: string }) => (
  <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
    <rect
      x="3"
      y="6"
      width="18"
      height="14"
      rx="2"
      stroke="currentColor"
      strokeWidth="2"
    />
    <circle cx="12" cy="13" r="4" stroke="currentColor" strokeWidth="2" />
  </svg>
);

const RefreshIcon = ({ className = "h-6 w-6" }: { className?: string }) => (
  <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
    <path
      d="M4 12a8 8 0 0 1 13.66-5.66L20 8"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
    <path
      d="M20 4v4h-4"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
    <path
      d="M20 12a8 8 0 0 1-13.66 5.66L4 16"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
    <path
      d="M4 20v-4h4"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

const EditIcon = ({ className = "h-6 w-6" }: { className?: string }) => (
  <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
    <path
      d="M4 20h4l10-10-4-4L4 16v4Z"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinejoin="round"
    />
    <path
      d="m12 6 4 4"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
    />
  </svg>
);

const SpeakerIcon = ({ className = "h-6 w-6" }: { className?: string }) => (
  <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
    <path
      d="M4 10v4h4l5 4V6L8 10H4Z"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinejoin="round"
    />
    <path
      d="M17 9a4 4 0 0 1 0 6"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
    />
    <path
      d="M19.5 6.5a7.5 7.5 0 0 1 0 11"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
    />
  </svg>
);

export default function SignToText() {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const connectionRef = useRef<signalR.HubConnection | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const frameIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const lastLetterRef = useRef("");
  const lastLetterTimeRef = useRef(0);

  const [isConnected, setIsConnected] = useState(false);
  const [isDetecting, setIsDetecting] = useState(false);
  const [detectedLetter, setDetectedLetter] = useState("");
  const [assembledWord, setAssembledWord] = useState("");
  const [detectedSentence, setDetectedSentence] = useState("");
  const [note, setNote] = useState("انقر على بداية التسجيل لتشغيل الكاميرا");

  const stopDetection = () => {
    setIsDetecting(false);
    if (frameIntervalRef.current) {
      clearInterval(frameIntervalRef.current);
      frameIntervalRef.current = null;
    }
  };

  useEffect(() => {
    const connection = new signalR.HubConnectionBuilder()
      .withUrl("https://ema2a.mooo.com/signHub", { withCredentials: true })
      .withAutomaticReconnect({
        nextRetryDelayInMilliseconds: (retryContext) =>
          Math.min(1000 * Math.pow(2, retryContext.previousRetryCount), 10000),
      })
      .configureLogging(signalR.LogLevel.Information)
      .build();

    connectionRef.current = connection;

    connection.on("ReceiveTranslation", (msg) => {
      const letter = msg?.letter || msg || "";
      if (typeof letter !== "string" || letter.length !== 1) {
        setNote("لا يمكن تحديد الإشارة، حاول مجددًا");
        return;
      }

      setDetectedLetter(letter);
      setNote("تم التقاط الإشارة بنجاح");

      const now = Date.now();
      if (letter !== lastLetterRef.current) {
        setAssembledWord((prev) => prev + letter);
        setDetectedSentence((prev) => prev + letter);
        lastLetterRef.current = letter;
        lastLetterTimeRef.current = now;
        return;
      }

      if (now - lastLetterTimeRef.current >= 2000) {
        setAssembledWord((prev) => prev + letter);
        setDetectedSentence((prev) => prev + letter);
        lastLetterTimeRef.current = now;
      }
    });

    connection.onreconnecting(() => {
      setIsConnected(false);
      setNote("جاري إعادة الاتصال بالخادم...");
    });

    connection.onreconnected(() => {
      setIsConnected(true);
      setNote("تمت إعادة الاتصال");
    });

    connection.onclose(() => {
      setIsConnected(false);
      setNote("تم قطع الاتصال");
      stopDetection();
    });

    connection
      .start()
      .then(() => {
        setIsConnected(true);
        setNote("متصل بالخادم");
      })
      .catch(() => setNote("تعذر الاتصال بالخادم"));

    return () => {
      stopDetection();
      void connection.stop();
      streamRef.current?.getTracks().forEach((track) => track.stop());
    };
  }, []);

  useEffect(() => {
    async function startCamera() {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: true,
        });
        streamRef.current = stream;

        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          void videoRef.current.play().catch(() => null);
        }
      } catch {
        setNote("تعذر الوصول إلى الكاميرا");
      }
    }

    void startCamera();
  }, []);

  const captureFrame = () => {
    const video = videoRef.current;
    if (!video || video.readyState < 2) return null;

    const canvas = document.createElement("canvas");
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;

    const ctx = canvas.getContext("2d");
    if (!ctx) return null;

    ctx.drawImage(video, 0, 0);
    return canvas.toDataURL("image/jpeg", 0.7);
  };

  const startDetection = () => {
    const connection = connectionRef.current;
    if (
      !connection ||
      connection.state !== signalR.HubConnectionState.Connected
    ) {
      setNote("الخادم غير متصل");
      return;
    }

    if (isDetecting) return;

    setIsDetecting(true);
    setNote("جاري التقاط الإشارات...");

    frameIntervalRef.current = setInterval(async () => {
      const imageData = captureFrame();
      if (!imageData) return;

      try {
        await connection.invoke("ProcessFrame", { imageData });
      } catch {
        setNote("حدث خطأ أثناء إرسال الإطار");
      }
    }, 300);
  };

  const resetAll = () => {
    setDetectedLetter("");
    setAssembledWord("");
    setDetectedSentence("");
    lastLetterRef.current = "";
    lastLetterTimeRef.current = 0;
    setNote("تم بدء جملة جديدة");
  };

  const speakSentence = () => {
    if (!detectedSentence) return;
    const utter = new SpeechSynthesisUtterance(detectedSentence);
    utter.lang = "ar";
    window.speechSynthesis.speak(utter);
  };

  const aiCorrect = async () => {
    if (!detectedSentence) return;

    try {
      const data = await finalizeSentence({ sentence: detectedSentence });
      setDetectedSentence(data?.data || detectedSentence);
      setNote("تم تصحيح الجملة");
    } catch {
      setNote("تعذر تصحيح الجملة");
    }
  };

  return (
    <section className="flex w-full h-fit p-8 px-16 gap-[13px] justify-between rounded-[35px] bg-white  shadow-[0_10px_10px_rgba(0,0,0,0.25)]">
      <div
        className="flex h-[535px] w-[500px] flex-col gap-[7px] px-[12px] drop-shadow-[0_6px_10px_rgba(0,0,0,0.25)]"
        dir="rtl"
      >
        <div className="flex h-[368px] w-full flex-col items-end gap-[10px]">
          <h2 className="h-[45px] w-full text-right text-2xl font-bold leading-[45px] text-black">
            ادخل الاشارة
          </h2>
          <div className="relative flex h-[307px] w-full items-center justify-center rounded-[20px] bg-[#101828] ">
            <video
              ref={videoRef}
              autoPlay
              playsInline
              muted
              className={`h-full w-full rounded-[12px] object-cover ${isDetecting ? "block" : "hidden"}`}
            />

            {!isDetecting && (
              <div className="flex h-[204px] w-[281px] flex-col items-center">
                <CameraIcon className="h-[114px] w-[114px] text-white" />
                <p className="h-[90px] w-full text-center text-2xl font-semibold leading-[45px] text-white">
                  انقر علي بداء التسجيل لتشغيل الكاميرا
                </p>
              </div>
            )}

            {isConnected && (
              <div className="absolute top-4 right-4 flex items-center gap-2 text-white">
                <span className="h-2.5 w-2.5 rounded-full bg-green-400 animate-pulse" />
                <span className="text-sm">متصل</span>
              </div>
            )}
          </div>
        </div>

        <div className="flex h-[161px] w-full flex-col items-end gap-4">
          <button
            onClick={isDetecting ? stopDetection : startDetection}
            className="flex h-14 w-full items-center justify-center gap-2 rounded-[25px] bg-[#19156C] shadow-[0_6px_10px_rgba(0,0,0,0.25)]"
          >
            <span className="text-2xl font-normal leading-[45px] text-white">
              {isDetecting ? "إيقاف التسجيل" : "بداية التسجيل"}
            </span>
            <CameraIcon className="h-8 w-8 text-white" />
          </button>

          <div className="flex h-[89px] w-full items-center rounded-[20px] bg-[#F1EAFA] px-[10px]">
            <div className="flex h-[89px] w-[390px] flex-col px-[10px] text-right text-[#19156C]">
              <span className="text-right text-base font-bold leading-[30px]">
                الملاحظات
              </span>
              <span className="text-right text-[20px] font-normal leading-[37px]">
                {note}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div
        className="flex h-[535px] w-[432px] flex-col items-center gap-6 rounded-[20px] px-[12px] drop-shadow-[0_6px_10px_rgba(0,0,0,0.25)]"
        dir="rtl"
      >
        <h2 className="h-[45px] w-full text-right text-2xl font-bold leading-[45px] text-black">
          ترجمة لغة الاشارة
        </h2>

        <div className="flex h-[115px] w-[408px] items-center rounded-[20px] bg-[#F1EAFA] px-[10px]">
          <div className="flex h-[89px] w-[390px] flex-col px-[10px] text-[#19156C]">
            <span className="text-right text-base font-bold leading-[30px]">
              الحرف المترجم
            </span>
            <span className="text-center text-[32px] font-semibold leading-[60px]">
              {detectedLetter || "-"}
            </span>
          </div>
        </div>

        <div className="flex h-[115px] w-[408px] items-center rounded-[20px] bg-[#F1EAFA] px-[10px]">
          <div className="flex h-[89px] w-[390px] flex-col px-[10px] text-[#19156C]">
            <span className="text-right text-base font-bold leading-[30px]">
              الجملة المكونه
            </span>
            <span className="text-center text-2xl font-semibold leading-[45px]">
              {assembledWord || "لم يتم التقاط أي حرف بعد"}
            </span>
          </div>
        </div>

        <div className="flex h-14 w-[408px] items-center justify-between gap-[8px]">
          <button
            onClick={resetAll}
            className="flex h-14 w-[200px] items-center justify-center gap-2 rounded-[25px] border-2 border-[#19156C] text-[#19156C] drop-shadow-[0_6px_10px_rgba(0,0,0,0.25)]"
          >
            <span className="text-base font-normal leading-[30px]">
              جملة جديدة
            </span>
            <RefreshIcon />
          </button>

          <button
            onClick={aiCorrect}
            disabled={!detectedSentence}
            className="flex h-14 w-[200px] items-center justify-center gap-2 rounded-[25px] border-2 border-[#19156C] text-[#19156C] disabled:opacity-50 drop-shadow-[0_6px_10px_rgba(0,0,0,0.25)]"
          >
            <span className="text-base font-normal leading-[30px]">
              تصحيح الجملة
            </span>
            <EditIcon />
          </button>
        </div>

        <button
          onClick={speakSentence}
          disabled={!detectedSentence}
          className="flex h-14 w-[408px] items-center justify-center gap-2 rounded-[25px] bg-[#19156C] shadow-[0_6px_10px_rgba(0,0,0,0.25)] text-white disabled:opacity-50"
        >
          <span className="text-[20px] font-normal leading-[37px]">
            نطق النص
          </span>
          <SpeakerIcon />
        </button>
      </div>
    </section>
  );
}
