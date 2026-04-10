import React, { useEffect, useMemo, useState } from "react";
import { Trash2, Volume2 } from "lucide-react";
import {
  deleteAllUserHistory,
  deleteUserHistoryRecord,
  getUserHistory,
  type UserRecordDTO,
} from "@/Api/APICalls";

type TableRow = {
  id: number;
  sentence: string;
  translation: string;
  formedAt?: string;
};

type PhraseTableProps = {
  onSpeakRow?: (row: TableRow) => void;
};

const PhraseTable: React.FC<PhraseTableProps> = ({ onSpeakRow }) => {
  const [rows, setRows] = useState<TableRow[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isDeletingAll, setIsDeletingAll] = useState(false);
  const [deletingRowId, setDeletingRowId] = useState<number | null>(null);

  const loadUserHistory = async () => {
    try {
      setIsLoading(true);
      const response = await getUserHistory();

      const mappedRows: TableRow[] = (response.data ?? []).map(
        (record: UserRecordDTO) => ({
          id: record.id ?? 0,
          sentence: record.formedSentence ?? "",
          translation: "-",
          formedAt: record.formedAt,
        }),
      );

      setRows(mappedRows);
    } catch (error) {
      console.error("Error loading user history:", error);
      setRows([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    void loadUserHistory();
  }, []);

  const handleDeleteRow = async (id: number) => {
    try {
      setDeletingRowId(id);
      await deleteUserHistoryRecord({ id });
      setRows((prev) => prev.filter((row) => row.id !== id));
    } catch (error) {
      console.error("Error deleting history record:", error);
    } finally {
      setDeletingRowId(null);
    }
  };

  const handleDeleteAll = async () => {
    try {
      setIsDeletingAll(true);
      await deleteAllUserHistory();
      setRows([]);
    } catch (error) {
      console.error("Error deleting all history:", error);
    } finally {
      setIsDeletingAll(false);
    }
  };

  const hasRows = useMemo(() => rows.length > 0, [rows]);

  return (
    <section
      dir="rtl"
      className="mt-32 mb-16 w-full max-w-[1080px] rounded-[46px] border border-white/50 bg-white/20 px-10 pt-9 pb-[52px] backdrop-blur-[6.8px]"
    >
      <div className="flex flex-col gap-3 overflow-hidden">
        <table className="w-full table-fixed border-separate border-spacing-y-3">
          <colgroup>
            <col className="w-[31px]" />
            <col className="w-[227px]" />
            <col className="w-[227px]" />
            <col className="w-[423px]" />
          </colgroup>

          <thead>
            <tr className="h-[60px] bg-[#19156C]">
              <th className="rounded-tr-[20px] py-0 font-normal">
                <div className="flex items-center justify-center text-white">
                  م
                </div>
              </th>

              <th className="px-0 py-0 font-normal">
                <HeaderCell>الجملة</HeaderCell>
              </th>

              <th className="px-0 py-0 font-normal">
                <HeaderCell>الترجمة</HeaderCell>
              </th>

              <th className="rounded-bl-[20px] py-0 font-normal" />
            </tr>
          </thead>

          <tbody>
            {isLoading ? (
              <tr className="bg-[#FBFBFB]">
                <td
                  colSpan={4}
                  className="rounded-[20px] px-5 py-6 text-center text-[#333333]"
                  style={{
                    fontFamily: '"El Messiri", sans-serif',
                    fontWeight: 400,
                  }}
                >
                  جاري تحميل السجل...
                </td>
              </tr>
            ) : !hasRows ? (
              <tr className="bg-[#FBFBFB]">
                <td
                  colSpan={4}
                  className="rounded-[20px] px-5 py-6 text-center text-[#333333]"
                  style={{
                    fontFamily: '"El Messiri", sans-serif',
                    fontWeight: 400,
                  }}
                >
                  لا يوجد سجل محفوظ حالياً
                </td>
              </tr>
            ) : (
              rows.map((row, index) => (
                <tr key={row.id} className="bg-[#FBFBFB]">
                  <td className="rounded-tr-[20px] px-5 py-3 align-middle">
                    <div className="flex h-[38px] w-[31px] items-center justify-center text-base text-[#333333]">
                      {index + 1}
                    </div>
                  </td>

                  <td className="px-0 py-3 align-middle">
                    <BodyCell className="text-right text-black">
                      {row.sentence}
                    </BodyCell>
                  </td>

                  <td className="px-0 py-3 align-middle">
                    <BodyCell className="text-center text-[#333333]">
                      {row.translation}
                    </BodyCell>
                  </td>

                  <td className="rounded-bl-[20px] px-5 py-3 align-middle">
                    <div className="flex w-[423px] items-center justify-center gap-[33px]">
                      <ActionButton
                        variant="primary"
                        icon={<Volume2 className="h-4 w-4" strokeWidth={1.8} />}
                        onClick={() => onSpeakRow?.(row)}
                      >
                        نطق الجملة
                      </ActionButton>

                      <ActionButton
                        variant="danger"
                        icon={<Trash2 className="h-5 w-5" strokeWidth={1.8} />}
                        onClick={() => handleDeleteRow(row.id)}
                        disabled={deletingRowId === row.id}
                      >
                        {deletingRowId === row.id ? "جاري الحذف" : "حذف الجملة"}
                      </ActionButton>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>

        <div className="flex justify-start pt-2">
          <button
            type="button"
            onClick={handleDeleteAll}
            disabled={!hasRows || isDeletingAll || isLoading}
            className="inline-flex h-12 w-[300px] items-center justify-center gap-2 rounded-[20px] bg-[#FF383C] text-[20px] text-white transition hover:opacity-95 active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-60"
            style={{ fontFamily: "Cairo, sans-serif" }}
          >
            <Trash2 className="h-8 w-8" strokeWidth={2} />
            <span>{isDeletingAll ? "جاري حذف الكل" : "حذف الكل"}</span>
          </button>
        </div>
      </div>
    </section>
  );
};

const HeaderCell: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div
    className="flex h-10 w-[227px] items-center justify-center px-[10px] text-center text-[20px] leading-[18px] text-white"
    style={{ fontFamily: '"El Messiri", sans-serif', fontWeight: 400 }}
  >
    {children}
  </div>
);

const BodyCell: React.FC<{ children: React.ReactNode; className?: string }> = ({
  children,
  className = "",
}) => (
  <div
    className={`flex h-10 w-[227px] items-center justify-center px-[10px] text-[16px] leading-[18px] ${className}`}
    style={{ fontFamily: '"El Messiri", sans-serif', fontWeight: 400 }}
  >
    {children}
  </div>
);

const ActionButton: React.FC<{
  children: React.ReactNode;
  icon: React.ReactNode;
  variant: "danger" | "primary";
  onClick?: () => void;
  disabled?: boolean;
}> = ({ children, icon, variant, onClick, disabled }) => {
  const styles =
    variant === "danger"
      ? "bg-[#FF383C] text-white"
      : "bg-[#19156C] text-white";

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={`inline-flex h-12 w-[120px] items-center justify-center gap-2 rounded-[20px] transition hover:opacity-95 active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-60 ${styles}`}
      style={{ fontFamily: "Cairo, sans-serif", fontWeight: 400 }}
    >
      <span className="text-[14px] leading-[26px]">{children}</span>
      {icon}
    </button>
  );
};

export default PhraseTable;
