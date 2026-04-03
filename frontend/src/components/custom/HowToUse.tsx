const cardBase =
  "flex flex-row flex-wrap items-start content-center bg-white rounded-[30px] shadow-[0px_6px_10px_rgba(0,0,0,0.25)] text-right text-[#19156C] text-[20px] leading-[37px] font-normal";

export default function HowToUSe() {
  return (
    <div className="flex flex-row items-start gap-[46px] font-['Cairo']">
      <section className="flex h-[677px] w-[490px] flex-col items-end gap-[15px]">
        <h2 className="h-[45px] w-[490px] self-stretch text-right text-[24px] font-bold leading-[45px] text-[#19156C] [text-shadow:0px_6px_10px_rgba(0,0,0,0.25)]">
          تحويل الإشارة إلى نص
        </h2>

        <div className="flex h-[617px] w-[490px] flex-col items-start gap-[17px] self-stretch">
          <div
            className={`${cardBase}  w-[490px] justify-center gap-[15px] px-[25px] pb-[10px] pt-[25px]`}
          >
            <p className=" w-[455px] grow text-right">
              تشغيل الكاميرا: المستخدم يفتح الكاميرا من داخل التطبيق.
            </p>
          </div>

          <div
            className={`${cardBase}  w-[490px] justify-center gap-[10px] px-[16px] pb-[10px] pt-[25px]`}
          >
            <p className="w-[464px] grow text-right">
              التقاط الإشارة: الكاميرا تلتقط حركة اليد أثناء الإشارة
            </p>
          </div>

          <div
            className={`${cardBase} w-[490px] justify-end content-end gap-[15px] px-[25px] pb-[10px] pt-[25px]`}
          >
            <p className=" w-[439px] text-right">
              تحليل الإشارة: نموذج ذكاء اصطناعي يقوم بالتعرف على شكل اليد
              وتحويله إلى الحرف العربي المقابل.
            </p>
          </div>

          <div
            className={`${cardBase}  w-[490px] justify-center gap-[15px] px-[25px] pb-[10px] pt-[25px]`}
          >
            <p className=" w-[464px] text-right">
              تجميع الحروف: الحروف التي تم التعرف عليها تُجمع لتكوين كلمة، ثم
              جملة.
            </p>
          </div>

          <div
            className={`${cardBase}  w-[490px] justify-center gap-[15px] px-[25px] pb-[10px] pt-[25px]`}
          >
            <p className=" w-[455px] grow text-right">
              تصحيح الجملة: المستخدم يقدر يضغط على زر «تصحيح الجملة» ليتم
              تعديلها لغويًا.
            </p>
          </div>
        </div>
      </section>

      <section className="flex h-[674px] w-[490px] flex-col items-end gap-[15px]">
        <h2 className="h-[45px] w-[490px] self-stretch text-right text-[24px] font-bold leading-[45px] text-[#19156C] [text-shadow:0px_6px_10px_rgba(0,0,0,0.25)]">
          تحويل النص إلى إشارة
        </h2>

        <div className="flex h-[614px] w-[490px] flex-col items-start gap-[17px] self-stretch">
          <div
            className={`${cardBase} h-[153px] w-[490px] justify-center gap-[15px] px-[25px] pb-[10px] pt-[25px]`}
          >
            <p className=" w-[455px] grow text-right">
              إدخال النص: يبدأ المستخدم بكتابة الجملة التي يريد ترجمتها (مثل:
              "بسم الله")، كما يمكنه تسجيل صوت ليتم تحويله إلى نص أولًا.
            </p>
          </div>

          <div
            className={`${cardBase} h-[119px] w-[490px] justify-end content-end gap-[15px] px-[25px] pb-[10px] pt-[25px]`}
          >
            <p className=" w-[439px] text-right">
              تحليل النص: يقوم التطبيق بتحليل الجملة المدخلة وتقسيمها إلى كلمات
              ثم إلى حروف منفصلة.
            </p>
          </div>

          <div
            className={`${cardBase} h-[126px] w-[490px] justify-center gap-[15px] px-[25px] pb-[10px] pt-[25px]`}
          >
            <p className=" w-[439px] text-right">
              مطابقة الإشارات: لكل حرف أو كلمة، يبحث التطبيق عن الصورة المطابقة
              في قاعدة بيانات لغة الإشارة.
            </p>
          </div>

          <div
            className={`${cardBase} h-[165px] w-[490px] justify-center gap-[15px] px-[25px] pb-[10px] pt-[25px]`}
          >
            <p className=" w-[455px] grow text-right">
              عرض الإشارات: يتم عرض الإشارات على الشاشة بالترتيب لتوضيح كيف
              تُقال الجملة بلغة الإشارة، بحيث يمكن للمستخدم فهم شكل الإشارات
              بسهولة.
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}
