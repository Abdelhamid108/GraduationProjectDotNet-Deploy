export const LetterCard = ({ label, image }) => (
  <div className="flex h-[99px] w-[89px] flex-col items-start gap-1">
    <div className="flex h-[65px] w-[82px] items-center justify-center rounded-[10px] bg-[#F1EAFA] px-[27px] py-[17px]">
      <img className="w-full h-full object-cover" src={image} />
    </div>
    <p className="h-[30px] w-[89px] text-center text-[16px] font-bold leading-[30px] text-[#19156C]">
      {label}
    </p>
  </div>
);

const DisplayWordCard = ({ wordImages, word }) => {
  return (
    <section className="flex h-fit w-[408px] flex-col items-center gap-8 rounded-[20px] bg-white px-[11px] pb-0 pl-[10px] pt-[5px]">
      <div
        className="flex h-fit w-[409px] flex-col items-start gap-3 px-[10px]"
        style={{ direction: "rtl" }}
      >
        <h2
          dir="rtl"
          className="h-[30px] w-[389px] self-stretch text-right text-[16px] font-bold leading-[30px] text-[#19156C]"
        >
          {word}
        </h2>
        <div
          className="flex items-center justify-center gap-[17px] flex-wrap direction-rtl"
          style={{ direction: "rtl" }}
        >
          {wordImages?.map((row, index) => (
            <LetterCard key={index} image={row} label={word[index]} />
          ))}
        </div>
      </div>
    </section>
  );
};

export default DisplayWordCard;
