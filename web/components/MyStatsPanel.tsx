import { motion } from 'framer-motion';
import { Clock, Crown, Flag, Flame, Gauge, Medal, Target, TrendingUp, Trophy, Zap } from 'lucide-react';
import type { PlayerStats } from '../App';

interface MyStatsPanelProps {
  playerRep: number;
  stats: PlayerStats;
}

const maxRep = 500;

const repTiers = [
  { name: 'Rookie', min: 0, max: 50, color: 'text-zinc-400' },
  { name: 'Amateur', min: 50, max: 150, color: 'text-green-400' },
  { name: 'Pro', min: 150, max: 300, color: 'text-blue-400' },
  { name: 'Elite', min: 300, max: 500, color: 'text-purple-400' },
  { name: 'Legend', min: 500, max: 999999, color: 'text-yellow-400' }
];

const defaultStats: PlayerStats = {
  totalRaces: 0,
  wins: 0,
  topThree: 0,
  winRate: 0,
  avgFinishPosition: 0,
  totalPrizeMoney: 0,
  currentStreak: 0,
  bestStreak: 0,
  repHistory: [],
  history: [],
  personalRecords: []
};

function getCurrentTier(rep: number) {
  return repTiers.find(tier => rep >= tier.min && rep < tier.max) || repTiers[repTiers.length - 1];
}

export default function MyStatsPanel({ playerRep, stats }: MyStatsPanelProps) {
  const safeStats = { ...defaultStats, ...(stats || {}) };
  const currentTier = getCurrentTier(playerRep);
  const nextTier = repTiers.find(t => t.min > playerRep);
  const repProgress = Math.min(100, (playerRep / maxRep) * 100);
  const history = safeStats.repHistory.length > 0 ? safeStats.repHistory : [playerRep];
  const maxHistoryRep = Math.max(1, ...history);

  return (
    <div className="space-y-6">
      <div className="relative overflow-hidden rounded-xl">
        <div className="absolute inset-0 bg-gradient-to-r from-red-950/60 via-black to-red-950/60" />
        <div className="absolute inset-0 hex-pattern opacity-50" />

        <div className="relative border border-red-900/40 rounded-xl p-6">
          <div className="flex items-center justify-between mb-4 gap-4">
            <div>
              <div className="text-zinc-500 text-xs uppercase tracking-wider mb-1 flex items-center gap-2">
                <Gauge size={12} />
                Current Rank
              </div>
              <motion.h2
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                className={`text-4xl font-bold ${currentTier.color}`}
              >
                {currentTier.name}
              </motion.h2>
            </div>
            <div className="text-right">
              <div className="flex items-center gap-2 justify-end">
                <Trophy size={22} className="text-yellow-500" />
                <motion.span
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ type: 'spring', stiffness: 200 }}
                  className="text-4xl font-bold text-white glow-text-red"
                >
                  {playerRep}
                </motion.span>
                <span className="text-zinc-500 text-lg">REP</span>
              </div>
              {nextTier && (
                <div className="flex items-center gap-2 justify-end mt-1">
                  <Zap size={12} className="text-red-400" />
                  <span className="text-zinc-500 text-sm">
                    <span className="text-red-400 font-bold">{Math.max(0, nextTier.min - playerRep)}</span> to {nextTier.name}
                  </span>
                </div>
              )}
            </div>
          </div>

          <div className="rep-bar-container h-5 relative rounded-lg overflow-hidden">
            <motion.div
              className="rep-bar-fill h-full rounded-lg relative"
              initial={{ width: 0 }}
              animate={{ width: `${repProgress}%` }}
              transition={{ duration: 1.5, ease: 'easeOut' }}
            >
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-shimmer" />
            </motion.div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-4 gap-4">
        {[
          { icon: Flag, value: safeStats.totalRaces, label: 'Total Races', color: 'text-white' },
          { icon: Crown, value: safeStats.wins, label: 'Wins', color: 'text-yellow-400' },
          { icon: Medal, value: safeStats.topThree, label: 'Podiums', color: 'text-amber-400' },
          { icon: TrendingUp, value: `${safeStats.winRate.toFixed(1)}%`, label: 'Win Rate', color: 'text-green-400' }
        ].map((stat, i) => (
          <motion.div
            key={stat.label}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.05 }}
            whileHover={{ scale: 1.04, y: -3 }}
            className="stat-card hover-lift glass-dark border border-zinc-800 rounded-xl p-4 text-center relative overflow-hidden"
          >
            <stat.icon size={22} className="mx-auto text-zinc-500 mb-2" />
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: i * 0.05 + 0.2, type: 'spring' }}
              className={`text-2xl font-bold ${stat.color}`}
            >
              {stat.value}
            </motion.div>
            <div className="text-zinc-600 text-xs uppercase mt-1">{stat.label}</div>
          </motion.div>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="glass-dark border border-zinc-800 rounded-xl p-5 hover:border-red-900/30 transition-all">
          <h3 className="text-zinc-400 text-xs uppercase tracking-wider mb-4 flex items-center gap-2">
            <Target size={14} className="text-red-400" />
            Performance
          </h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-zinc-500">Avg Finish</span>
              <span className="text-white font-bold text-lg">
                {safeStats.avgFinishPosition > 0 ? `#${safeStats.avgFinishPosition.toFixed(1)}` : '-'}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-zinc-500">Best Time</span>
              <span className="text-green-400 font-bold text-lg font-mono">
                {safeStats.bestTime ? formatTime(safeStats.bestTime) : '-'}
              </span>
            </div>
            <div className="text-zinc-600 text-xs flex items-center gap-1">
              <Flag size={10} />
              {safeStats.bestTimeRoute || 'No route record yet'}
            </div>
          </div>
        </div>

        <div className="glass-dark border border-zinc-800 rounded-xl p-5 hover:border-orange-900/30 transition-all">
          <h3 className="text-zinc-400 text-xs uppercase tracking-wider mb-4 flex items-center gap-2">
            <Flame size={14} className="text-orange-400" />
            Streaks
          </h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-zinc-500">Current</span>
              <span className={`font-bold flex items-center gap-1 ${safeStats.currentStreak > 0 ? 'text-orange-400' : 'text-zinc-600'}`}>
                {safeStats.currentStreak > 0 && <Flame size={16} className="text-orange-500" />}
                <span className="text-lg">{safeStats.currentStreak}</span> wins
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-zinc-500">Best</span>
              <span className="text-yellow-400 font-bold text-lg">{safeStats.bestStreak} wins</span>
            </div>
          </div>
        </div>
      </div>

      {safeStats.history.length > 0 && (
        <div className="glass-dark border border-zinc-800 rounded-xl p-5">
          <h3 className="text-zinc-400 text-xs uppercase tracking-wider mb-4 flex items-center gap-2">
            <Clock size={14} className="text-red-400" />
            Latest Run
          </h3>
          <div className="flex items-center justify-between gap-4">
            <div className="min-w-0">
              <div className="text-white font-bold text-lg truncate">{safeStats.history[0].routeName}</div>
              <div className="text-zinc-500 text-sm">
                {safeStats.history[0].dnf ? 'DNF' : `#${safeStats.history[0].position}/${safeStats.history[0].totalPlayers}`} - +{safeStats.history[0].repGained} REP
              </div>
            </div>
            <div className="text-right shrink-0">
              <div className="text-green-400 font-bold">${(safeStats.history[0].prizeWon || 0).toLocaleString()}</div>
              <div className="text-zinc-600 text-xs">Prize won</div>
            </div>
          </div>
        </div>
      )}

      <div className="relative overflow-hidden rounded-xl">
        <div className="absolute inset-0 bg-gradient-to-r from-green-950/40 via-black to-green-950/40" />
        <div className="relative border border-green-900/40 rounded-xl p-5 flex items-center justify-between gap-4">
          <div>
            <div className="text-zinc-500 text-xs uppercase tracking-wider flex items-center gap-2">
              <Trophy size={12} className="text-green-400" />
              Total Prize Money
            </div>
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              className="text-4xl font-bold text-green-400 glow-text-green"
            >
              ${safeStats.totalPrizeMoney.toLocaleString()}
            </motion.div>
          </div>
          <div className="text-right text-zinc-600 text-sm">
            <div><span className="text-yellow-400 font-semibold">{safeStats.wins}</span> wins</div>
            <div><span className="text-amber-400 font-semibold">{safeStats.topThree}</span> podiums</div>
          </div>
        </div>
      </div>

      <div className="glass-dark border border-zinc-800 rounded-xl p-5">
        <h3 className="text-zinc-400 text-xs uppercase tracking-wider mb-4 flex items-center gap-2">
          <Clock size={14} className="text-red-400" />
          Reputation Growth
        </h3>
        <div className="h-28 flex items-end gap-2">
          {history.map((rep, i) => {
            const height = (rep / maxHistoryRep) * 100;
            return (
              <motion.div
                key={`${rep}-${i}`}
                initial={{ height: 0 }}
                animate={{ height: `${Math.max(8, height)}%` }}
                transition={{ delay: i * 0.03, duration: 0.3 }}
                className="flex-1 bg-gradient-to-t from-red-600 via-red-500 to-red-400 rounded-t opacity-70 hover:opacity-100 transition-all relative group"
              >
                <div className="absolute -top-6 left-1/2 -translate-x-1/2 bg-black border border-zinc-700 rounded px-2 py-1 text-[10px] text-red-400 font-bold opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                  {rep} REP
                </div>
              </motion.div>
            );
          })}
        </div>
        <div className="flex justify-between mt-2 text-[10px] text-zinc-600">
          <span>Older</span>
          <span>Now</span>
        </div>
      </div>
    </div>
  );
}

function formatTime(ms: number) {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  const centiseconds = Math.floor((ms % 1000) / 10);
  return `${minutes}:${pad2(seconds)}.${pad2(centiseconds)}`;
}

function pad2(value: number) {
  return value < 10 ? `0${value}` : String(value);
}
