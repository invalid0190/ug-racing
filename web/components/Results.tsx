import { motion } from 'framer-motion';
import { Clock, DollarSign, Flame, Star, Trophy, X } from 'lucide-react';
import { t } from '../hooks/useLocale';

interface ResultItem {
  name: string;
  position: number;
  repGained: number;
  prizeWon?: number;
  time?: number | null;
  dnf?: boolean;
}

interface ResultsProps {
  results: ResultItem[];
  prizePool: number;
  onClose: () => void;
}

const speedLines = Array.from({ length: 6 }, (_, i) => ({
  top: `${12 + i * 10}%`,
  width: `${36 + (i % 4) * 8}%`,
  delay: `${i * 0.3}s`,
  duration: `${2.5 + (i % 3) * 0.4}s`,
  reverse: i % 2 === 0
}));

const placeBadgeStyles = [
  'border-yellow-400/70 bg-yellow-500/15 text-yellow-300',
  'border-zinc-400/60 bg-zinc-400/10 text-zinc-200',
  'border-amber-600/60 bg-amber-600/10 text-amber-500'
];

export default function Results({ results, prizePool, onClose }: ResultsProps) {
  const safeResults = Array.isArray(results) ? results.filter(Boolean) : [];
  const rankedResults = safeResults
    .map((result, index) => ({ ...result, fallbackPosition: index + 1 }))
    .sort((a, b) => {
      const posA = Number(a.position) || a.fallbackPosition;
      const posB = Number(b.position) || b.fallbackPosition;
      if (posA !== posB) return posA - posB;
      if (a.dnf !== b.dnf) return a.dnf ? 1 : -1;
      return (Number(a.time) || Number.MAX_SAFE_INTEGER) - (Number(b.time) || Number.MAX_SAFE_INTEGER);
    });
  const winner = rankedResults[0];

  const pad = (n: number) => (n < 10 ? '0' + n : n.toString());

  const formatMoney = (value?: number) => Math.max(0, Number(value) || 0).toLocaleString();

  const formatTime = (ms?: number | null, dnf?: boolean) => {
    if (dnf) return 'DNF';
    const value = Number(ms);
    if (!Number.isFinite(value) || value <= 0) return '--:--';

    const mins = Math.floor(value / 60000);
    const secs = Math.floor((value % 60000) / 1000);
    const msPart = Math.floor((value % 1000) / 10);
    return `${mins}:${pad(secs)}.${pad(msPart)}`;
  };

  return (
    <div className="fixed inset-0 pointer-events-auto overflow-hidden">
      <div className="absolute inset-0 results-vignette" />
      <div className="speed-lines-bg opacity-25">
        {speedLines.map((line, i) => (
          <div
            key={i}
            className={`speed-line ${line.reverse ? 'reverse' : ''}`}
            style={{
              top: line.top,
              width: line.width,
              animationDelay: line.delay,
              animationDuration: line.duration
            }}
          />
        ))}
      </div>

      <motion.div
        initial={{ x: 36, opacity: 0 }}
        animate={{ x: 0, opacity: 1 }}
        exit={{ x: 36, opacity: 0 }}
        className="results-panel absolute right-4 sm:right-8 top-1/2 -translate-y-1/2 w-[440px] max-w-[calc(100vw-2rem)] rounded-lg p-5 z-10"
      >
        <div className="flex items-center justify-between gap-4 mb-5">
          <div className="flex items-center gap-3 min-w-0">
            <Flame className="text-red-500 shrink-0" size={28} />
            <div className="min-w-0">
              <p className="text-[10px] font-bold uppercase tracking-[0.22em] text-zinc-500">{t('finish_complete', 'Finish Complete')}</p>
              <h2 className="text-2xl font-bold text-white uppercase tracking-wider truncate">
                {t('race_results', 'Race Results')}
              </h2>
            </div>
          </div>
          <button
            type="button"
            aria-label="Close results"
            onClick={onClose}
            className="grid h-10 w-10 place-items-center rounded-md border border-zinc-800 bg-black/50 text-zinc-500 transition-colors hover:border-red-500/60 hover:text-red-400"
          >
            <X size={24} />
          </button>
        </div>

        <div className="mb-4 grid grid-cols-[1fr_auto] items-center gap-4 rounded-lg border border-green-500/30 bg-green-950/25 px-4 py-3">
          <div>
            <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-zinc-500">{t('total_prize_pool', 'Total Prize Pool')}</p>
            <p className="mt-1 text-sm text-zinc-400">{rankedResults.length} driver{rankedResults.length === 1 ? '' : 's'} recorded</p>
          </div>
          <div className="flex items-center gap-1 text-2xl font-black text-green-400">
            <DollarSign size={18} className="text-green-500" />
            {formatMoney(prizePool)}
          </div>
        </div>

        {rankedResults.length === 0 ? (
          <div className="mb-4 rounded-lg border border-zinc-800 bg-black/60 py-10 text-center text-zinc-400">
            {t('no_finishers', 'No finishers recorded.')}
          </div>
        ) : (
          <div className="mb-4">
            <div className="mb-3 rounded-lg border border-yellow-500/45 bg-black/85 p-4">
              <div className="flex items-start justify-between gap-4">
                <div className="min-w-0">
                  <div className="mb-2 flex items-center gap-2 text-yellow-400">
                    <Trophy size={22} />
                    <span className="text-xs font-black uppercase tracking-[0.2em]">{t('winner', 'Winner')}</span>
                  </div>
                  <p className="truncate text-2xl font-black text-white">{winner?.name || t('unknown', 'Unknown')}</p>
                  <div className="mt-2 flex flex-wrap items-center gap-3 text-xs">
                    <span className="flex items-center gap-1 font-bold text-yellow-500">
                      <Star size={13} />+{winner?.repGained || 0} REP
                    </span>
                    <span className="flex items-center gap-1 font-bold text-zinc-400">
                      <Clock size={13} />{formatTime(winner?.time, winner?.dnf)}
                    </span>
                    {winner?.prizeWon ? (
                      <span className="font-bold text-green-400">${formatMoney(winner.prizeWon)}</span>
                    ) : null}
                  </div>
                </div>
                <div className="grid h-14 w-14 shrink-0 place-items-center rounded-lg border border-yellow-400/50 bg-yellow-500/15 text-yellow-300">
                  <Trophy size={28} />
                </div>
              </div>
            </div>

            <div className="mb-2 flex items-center justify-between text-[10px] font-bold uppercase tracking-[0.18em] text-zinc-600">
              <span>{t('final_standings', 'Final Standings')}</span>
              <span>{t('time', 'Time')}</span>
            </div>
            <div className="space-y-2 max-h-[260px] overflow-y-auto pr-1">
              {rankedResults.map((result, index) => {
                const position = index + 1;
                const badgeStyle = placeBadgeStyles[index] || 'border-zinc-800 bg-black/50 text-zinc-500';
                const isWinner = index === 0;

                return (
                  <div
                    key={`${result.name || 'racer'}-${position}-${index}`}
                    className={`result-row flex items-center gap-3 rounded-lg border px-3 py-2.5 ${isWinner ? 'border-yellow-500/50 bg-black/80' : 'border-zinc-800 bg-black/75'}`}
                  >
                    <div className={`grid h-9 w-9 shrink-0 place-items-center rounded-md border text-sm font-black ${badgeStyle}`}>
                      {position}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="truncate font-bold text-white">{result.name || t('unknown', 'Unknown')}</div>
                      <div className="mt-0.5 flex items-center gap-3 text-xs">
                        <span className="flex items-center gap-1 text-yellow-500">
                          <Star size={12} />+{result.repGained || 0} REP
                        </span>
                        {result.prizeWon ? <span className="text-green-400">${formatMoney(result.prizeWon)}</span> : null}
                      </div>
                    </div>
                    <div className={`shrink-0 text-right text-xs font-bold ${result.dnf ? 'text-red-400' : 'text-zinc-400'}`}>
                      {formatTime(result.time, result.dnf)}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        <button
          type="button"
          onClick={onClose}
          className="btn-join-race w-full rounded-lg py-3 text-base font-bold uppercase tracking-wider"
        >
          {t('continue', 'Continue')}
        </button>
      </motion.div>
    </div>
  );
}
