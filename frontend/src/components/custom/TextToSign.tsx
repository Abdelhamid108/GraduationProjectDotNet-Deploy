import { useMemo, useRef, useState } from "react";
import { toast } from "sonner";
import { textToSign, audioToText } from "@/Api/APICalls";
import DisplayWordCard from "./DisplayCardLetters";

const ARABIC_TEXT_REGEX = /^[\u0600-\u06FF\s]+$/;

export default function TextToSign() {
  const [inputText, setInputText] = useState("");
  const [translated, setTranslated] = useState<string[]>([]);
  const [latestTranslated, setLatestTranslated] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);

  const hasTranslation = translated.length > 0;

  const previewText = useMemo(() => {
    if (isLoading) return "جارٍ المعالجة...";
    if (error) return error;
    if (hasTranslation) return null;
    return "ادخل نصًا وانقر على ترجمة لعرض لغة الإشارة";
  }, [error, hasTranslation, isLoading]);

  const isArabicText = (text: string) => ARABIC_TEXT_REGEX.test(text.trim());

  const sanitizeArabicInput = (value: string) => {
    return value.replace(/[^\u0600-\u06FF\s]/g, "");
  };

  const blobToBase64 = (blob: Blob): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(blob);
      reader.onloadend = () => {
        const base64 = reader.result?.toString().split(",")[1];
        if (base64) resolve(base64);
        else reject("Base64 conversion failed");
      };
      reader.onerror = reject;
    });
  };

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: true,
      });

      const mediaRecorder = new MediaRecorder(stream);
      mediaRecorderRef.current = mediaRecorder;
      audioChunksRef.current = [];

      mediaRecorder.ondataavailable = (event) => {
        audioChunksRef.current.push(event.data);
      };

      mediaRecorder.onstop = handleAudioStop;

      mediaRecorder.start();
      setIsRecording(true);
    } catch (err) {
      console.error(err);
      setError("تعذر الوصول إلى الميكروفون");
      toast.error("تعذر الوصول إلى الميكروفون");
    }
  };

  const stopRecording = () => {
    mediaRecorderRef.current?.stop();
    setIsRecording(false);
  };

  const handleAudioStop = async () => {
    try {
      setIsLoading(true);
      setError(null);

      const audioBlob = new Blob(audioChunksRef.current, {
        type: "audio/webm",
      });

      const base64Audio = await blobToBase64(audioBlob);

      const response = await audioToText({
        audioData: base64Audio,
        mimeType: "audio/webm",
      });

      const text = response.data?.trim();

      if (!text) {
        setError("لم يتم التعرف على الصوت");
        toast.error("لم يتم التعرف على الصوت");
        return;
      }

      if (!isArabicText(text)) {
        setInputText("");
        setTranslated([]);
        setError("يُسمح بإدخال الحروف العربية فقط");
        toast.error("يُسمح بإدخال الحروف العربية فقط");
        return;
      }

      setInputText(text);
    } catch (err) {
      console.error(err);
      setError("حدث خطأ أثناء تحويل الصوت");
      toast.error("حدث خطأ أثناء تحويل الصوت");
    } finally {
      setIsLoading(false);
    }
  };

  const handleInputChange = (event: React.ChangeEvent<HTMLTextAreaElement>) => {
    const value = event.target.value;
    const sanitizedValue = sanitizeArabicInput(value);

    if (value !== sanitizedValue) {
      toast.error("يُسمح بإدخال الحروف العربية فقط");
    }

    setInputText(sanitizedValue);
    setError(null);
  };

  const handleTranslate = async () => {
    const normalizedInput = inputText.trim();

    if (!normalizedInput) {
      setTranslated([]);
      setError("الرجاء إدخال نص قبل الترجمة");
      toast.error("الرجاء إدخال نص قبل الترجمة");
      return;
    }

    if (!isArabicText(normalizedInput)) {
      setTranslated([]);
      setError("يُسمح بإدخال الحروف العربية فقط");
      toast.error("يُسمح بإدخال الحروف العربية فقط");
      return;
    }

    try {
      setIsLoading(true);
      setError(null);

      const response = await textToSign({ text: normalizedInput });
      const signs = response.data ?? [];

      if (!signs.length) {
        setTranslated([]);
        setError("لم يتم العثور على ترجمة لهذا النص");
        toast.error("لم يتم العثور على ترجمة لهذا النص");
        return;
      }

      setLatestTranslated(normalizedInput);
      setTranslated(signs);
    } catch (translateError) {
      setTranslated([]);
      setError("حدث خطأ أثناء الترجمة. حاول مرة أخرى.");
      toast.error("حدث خطأ أثناء الترجمة. حاول مرة أخرى.");
      console.error(translateError);
    } finally {
      setIsLoading(false);
    }
  };

  const handleVoiceClick = () => {
    if (isRecording) stopRecording();
    else startRecording();
  };

  return (
    <section
      dir="rtl"
      className="mx-auto flex w-full flex-row items-start justify-between gap-[13px] rounded-[35px] bg-white px-8 py-7 shadow-[0_10px_10px_rgba(0,0,0,0.25)]"
      style={{ direction: "ltr" }}
    >
      <div className="flex h-full w-full max-w-[475px] flex-col items-start gap-8 px-3">
        <div className="flex w-full flex-col items-start gap-4">
          <h2 className="w-full text-right text-2xl font-bold">
            ادخل النص العربي
          </h2>

          <textarea
            value={inputText}
            onChange={handleInputChange}
            placeholder="ادخل النص العربي هنا"
            className="h-44 w-full resize-none rounded-[10px] bg-[#F3F3F5] px-6 py-5 text-right"
          />
        </div>

        <div className="flex w-full flex-col items-end gap-6">
          <button
            type="button"
            onClick={handleTranslate}
            disabled={isLoading}
            className="flex h-14 w-full items-center justify-center rounded-[25px] bg-[#19156C] text-white"
          >
            {isLoading ? "جارٍ المعالجة..." : "ترجمة النص إلى إشارة"}
          </button>

          <button
            type="button"
            onClick={handleVoiceClick}
            className={`flex h-14 w-full items-center justify-center rounded-[25px] border-2 transition ${
              isRecording
                ? "border-red-500 bg-red-500 text-white"
                : "border-[#19156C] text-[#19156C]"
            }`}
          >
            {isRecording ? "إيقاف التسجيل..." : "التسجيل الصوتي"}
          </button>
        </div>
      </div>

      <div className="flex h-full w-full max-w-[411px] flex-col items-center gap-3 px-3">
        <h2 className="w-full text-right text-2xl font-bold">
          ترجمة لغة الإشارة
        </h2>

        {translated.length ? (
          translated.map((word, ind) => (
            <DisplayWordCard
              wordImages={word}
              word={latestTranslated.split(" ")[ind]}
              key={ind}
            />
          ))
        ) : (
          <div className="flex min-h-[480px] w-full items-center justify-center rounded-[35px] border-[3px] border-dashed border-[#898989] bg-[#E7E7E7]">
            <p className="text-2xl text-[#898989]">{previewText}</p>
          </div>
        )}
      </div>
    </section>
  );
}
