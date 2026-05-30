import { motion } from 'framer-motion';
import {
  Award,
  CalendarClock,
  Crown,
  Flag,
  History,
  Medal,
  Route,
  Sparkles,
  Timer,
  Trophy,
  Wallet
} from 'lucide-react';
import type { PlayerStats, RaceHistoryEntry, RouteSummary } from '../App';

interface RaceHistoryPanelProps {
  stats: PlayerStats;
  routes: RouteSummary[];
}

export default function RaceHistoryPanel({ stats, routes }: RaceHistoryPanelProps) {
  const history = Array.isArray(stats.history) ? stats.history : [];
  const personalRecords = Array.isArray(stats.personalRecords) ? stats.personalRecords : [];
  const globalRecords = routes
    .filter(route => route.record?.time)
    .sort((a, b) => (a.record?.time || 0) - (b.record?.time || 0));
  const bestRace = history.find(entry => !entry.dnf && entry.time);
  const totalHistoryPrize = history.reduce((sum, entry) => sum + (Number(entry.prizeWon) || 0), 0);
  const recordCount = history.filter(entry => entry.personalBest || entry.globalRecord).length;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-3">
            <History size={24} className="text-red-500" />
            Race History
          </h2>
          <p className="text-zinc-500 text-sm mt-1">Recent results, personal bests, and route records</p>
        </div>
        <div className="text-right shrink-0">
          <div className="text-zinc-500 text-xs uppercase tracking-wider">Stored Races</div>
          <div className="text-3xl font-bold text-red-400 glow-text-red">{history.length}</div>
        </div>
      </div>

      <div className="grid grid-cols-4 gap-4">
        <HistoryMetric icon={Flag} label="Races" value={stats.totalRaces || 0} />
        <HistoryMetric icon={Trophy} label="Wins" value={stats.wins || 0} tone="gold" />
        <HistoryMetric icon={Sparkles} label="Records" value={recordCount} tone="red" />
        <HistoryMetric icon={Wallet} label="History Prize" value={`$${totalHistoryPrize.toLocaleString()}`} tone="green" />
      </div>

      <div className="grid grid-cols-[1.3fr_0.7fr] gap-6">
        <div className="glass-dark border border-zinc-800 rounded-xl p-5 min-h-[420px]">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-zinc-300 font-bold uppercase tracking-wider flex items-center gap-2">
              <CalendarClock size={16} className="text-red-400" />
              Recent Runs
            </h3>
            {bestRace && (
              <span className="text-xs text-zinc-500">
                Best: <span className="text-green-400 font-mono">{formatTime(bestRace.time)}</span>
              </span>
            )}
          </div>

          {history.length === 0 ? (
            <EmptyHistory />
          ) : (
            <div className="space-y-3">
              {history.slice(0, 12).map((entry, index) => (
                <HistoryRow key={entry.id || `${entry.routeName}-${index}`} entry={entry} index={index} />
              ))}
            </div>
          )}
        </div>

        <div className="space-y-6">
          <div className="glass-dark border border-zinc-800 rounded-xl p-5">
            <h3 className="text-zinc-300 font-bold uppercase tracking-wider flex items-center gap-2 mb-4">
              <Medal size={16} className="text-yellow-400" />
              Personal Bests
            </h3>

            {personalRecords.length === 0 ? (
              <SmallEmpty label="No personal records yet" />
            ) : (
              <div className="space-y-3">
                {personalRecords.slice(0, 5).map((record, index) => (
                  <motion.div
                    key={record.routeId}
                    initial={{ opacity: 0, y: 12 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.04 }}
                    className="rounded-lg border border-yellow-900/40 bg-yellow-950/10 p-3"
                  >
                    <div className="flex items-center justify-between gap-3">
                      <div className="min-w-0">
                        <div className="text-white font-bold truncate">{record.routeName}</div>
                        <div className="text-zinc-600 text-xs">{formatDate(record.finishedAt)}</div>
                      </div>
                      <div className="text-right shrink-0">
                        <div className="text-yellow-400 font-mono font-bold">{formatTime(record.time)}</div>
                        <div className="text-zinc-600 text-xs">PB</div>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            )}
          </div>

          <div className="glass-dark border border-zinc-800 rounded-xl p-5">
            <h3 className="text-zinc-300 font-bold uppercase tracking-wider flex items-center gap-2 mb-4">
              <Crown size={16} className="text-red-400" />
              Route Kings
            </h3>

            {globalRecords.length === 0 ? (
              <SmallEmpty label="No global route records yet" />
            ) : (
              <div className="space-y-3">
                {globalRecords.slice(0, 5).map((route, index) => (
                  <motion.div
                    key={route.id}
                    initial={{ opacity: 0, y: 12 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.04 }}
                    className="rounded-lg border border-red-900/40 bg-red-950/10 p-3"
                  >
                    <div className="flex items-center justify-between gap-3">
                      <div className="min-w-0">
                        <div className="text-white font-bold truncate">{route.name}</div>
                        <div className="text-zinc-600 text-xs truncate">{route.record?.name || 'Unknown Racer'}</div>
                      </div>
                      <div className="text-right shrink-0">
                        <div className="text-red-400 font-mono font-bold">{formatTime(route.record?.time)}</div>
                        <div className="text-zinc-600 text-xs">RECORD</div>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function HistoryRow({ entry, index }: { entry: RaceHistoryEntry; index: number }) {
  const isWin = entry.position === 1 && !entry.dnf;
  const isPodium = entry.position <= 3 && !entry.dnf;

  return (
    <motion.div
      initial={{ opacity: 0, x: -18 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: index * 0.03 }}
      className={`result-row rounded-xl border p-4 flex items-center gap-4 ${
        entry.globalRecord
          ? 'border-red-600/50 bg-red-950/20'
          : entry.personalBest
            ? 'border-yellow-600/40 bg-yellow-950/10'
            : 'border-zinc-800 bg-black/35'
      }`}
    >
      <div className={`w-12 h-12 rounded-xl flex items-center justify-center border shrink-0 ${
        isWin
          ? 'border-yellow-500/60 text-yellow-400 bg-yellow-950/20'
          : isPodium
            ? 'border-amber-700/50 text-amber-400 bg-amber-950/10'
            : 'border-zinc-700 text-zinc-400 bg-zinc-900'
      }`}>
        {entry.dnf ? 'DNF' : `#${entry.position || '-'}`}
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <div className="text-white font-bold truncate">{entry.routeName || 'Unknown Route'}</div>
          {entry.globalRecord && <Badge label="Global Record" tone="red" />}
          {entry.personalBest && !entry.globalRecord && <Badge label="Personal Best" tone="gold" />}
        </div>
        <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-zinc-500 mt-1">
          <span className="flex items-center gap-1">
            <Timer size={12} />
            {entry.dnf ? 'Did not finish' : formatTime(entry.time)}
          </span>
          <span>{entry.totalPlayers || 0} drivers</span>
          <span>{formatDate(entry.finishedAt)}</span>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 text-right shrink-0 min-w-[150px]">
        <div>
          <div className="text-green-400 font-bold">${(Number(entry.prizeWon) || 0).toLocaleString()}</div>
          <div className="text-zinc-600 text-[10px] uppercase">Prize</div>
        </div>
        <div>
          <div className="text-yellow-400 font-bold">+{Number(entry.repGained) || 0}</div>
          <div className="text-zinc-600 text-[10px] uppercase">Rep</div>
        </div>
      </div>
    </motion.div>
  );
}

function HistoryMetric({ icon: Icon, label, value, tone = 'plain' }: {
  icon: typeof Flag;
  label: string;
  value: number | string;
  tone?: 'plain' | 'gold' | 'red' | 'green';
}) {
  const color = tone === 'gold' ? 'text-yellow-400' : tone === 'red' ? 'text-red-400' : tone === 'green' ? 'text-green-400' : 'text-white';

  return (
    <motion.div
      whileHover={{ scale: 1.03, y: -2 }}
      className="glass-dark border border-zinc-800 rounded-xl p-4"
    >
      <div className="text-zinc-500 text-xs uppercase tracking-wider mb-1 flex items-center gap-2">
        <Icon size={13} />
        {label}
      </div>
      <div className={`text-2xl font-bold ${color}`}>{value}</div>
    </motion.div>
  );
}

function Badge({ label, tone }: { label: string; tone: 'red' | 'gold' }) {
  return (
    <span className={`text-[10px] uppercase tracking-wider px-2 py-0.5 rounded border ${
      tone === 'red'
        ? 'text-red-300 border-red-600/50 bg-red-950/40'
        : 'text-yellow-300 border-yellow-600/50 bg-yellow-950/30'
    }`}>
      {label}
    </span>
  );
}

function EmptyHistory() {
  return (
    <div className="h-72 flex flex-col items-center justify-center text-zinc-600 border border-zinc-800 rounded-xl bg-black/20">
      <Route size={44} className="mb-3 opacity-40" />
      <div className="text-zinc-400 font-semibold">No race history yet</div>
      <div className="text-sm mt-1">Finish a race and your timeline will appear here.</div>
    </div>
  );
}

function SmallEmpty({ label }: { label: string }) {
  return (
    <div className="rounded-lg border border-zinc-800 bg-black/25 p-4 text-center text-zinc-600 text-sm">
      {label}
    </div>
  );
}

function formatDate(value?: number) {
  if (!value) return 'Unknown time';
  const timestamp = value < 1000000000000 ? value * 1000 : value;
  return new Date(timestamp).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}

function formatTime(ms?: number) {
  if (!ms) return '-';
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  const centiseconds = Math.floor((ms % 1000) / 10);
  return `${minutes}:${pad2(seconds)}.${pad2(centiseconds)}`;
}

function pad2(value: number) {
  return value < 10 ? `0${value}` : String(value);
}
