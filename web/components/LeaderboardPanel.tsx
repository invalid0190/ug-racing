import { motion } from 'framer-motion';
import { Award, Crown, Flame, Medal, TrendingUp, Trophy, Zap } from 'lucide-react';

interface LeaderboardPanelProps {
  data: any[];
  playerRep: number;
  playerRank?: number;
}

const rankIcons = [Crown, Medal, Award];

export default function LeaderboardPanel({ data, playerRep, playerRank }: LeaderboardPanelProps) {
  const displayData = Array.isArray(data) ? data.filter(Boolean).slice(0, 25) : [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-3">
            <Trophy size={24} className="text-yellow-500" />
            Leaderboard
          </h2>
          <p className="text-zinc-500 text-sm mt-1">Top street racers by reputation</p>
        </div>
        <div className="text-right">
          <div className="text-zinc-500 text-xs uppercase tracking-wider">Your Position</div>
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            className="text-3xl font-bold text-red-400 glow-text-red"
          >
            {playerRank ? `#${playerRank}` : '--'}
          </motion.div>
        </div>
      </div>

      {displayData.length === 0 ? (
        <div className="text-center text-zinc-500 py-16 border border-zinc-800 rounded-xl bg-black/30">
          <Trophy size={42} className="mx-auto mb-3 opacity-30" />
          <p className="text-lg">No racers ranked yet</p>
          <p className="text-zinc-600 text-sm mt-1">Finish races to build the leaderboard.</p>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-3 gap-4 items-end">
            {displayData.slice(0, 3).map((player, index) => {
              const rank = getRank(player, index);
              const Icon = rankIcons[index] || Trophy;
              const height = index === 0 ? 'h-40' : index === 1 ? 'h-32' : 'h-28';
              return (
                <motion.div
                  key={player.identifier || player.name || rank}
                  initial={{ y: 50, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ delay: 0.1 + index * 0.1 }}
                  className={index === 0 ? 'order-2' : index === 1 ? 'order-1' : 'order-3'}
                >
                  <PodiumCard player={player} rank={rank} Icon={Icon} height={height} isGold={rank === 1} />
                </motion.div>
              );
            })}
          </div>

          <div className="space-y-2">
            {displayData.slice(3).map((player, index) => {
              const rank = getRank(player, index + 3);
              return (
                <motion.div
                  key={player.identifier || player.name || rank}
                  initial={{ x: -20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.35 + index * 0.03 }}
                  whileHover={{ scale: 1.01, x: 4 }}
                  className="glass-dark border border-zinc-800 hover:border-red-900/40 rounded-xl p-4 flex items-center gap-4 transition-all group"
                >
                  <div className="w-12 h-12 rounded-xl bg-zinc-900 border border-zinc-800 flex items-center justify-center text-zinc-400 font-bold text-lg group-hover:border-red-900/50 transition-colors">
                    #{rank}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-white font-semibold flex items-center gap-2">
                      <span className="truncate">{player.name || 'Unknown Racer'}</span>
                      {(Number(player.streak) || 0) >= 3 && (
                        <span className="flex items-center gap-1 text-orange-400 text-xs shrink-0">
                          <Flame size={12} />
                          {player.streak}
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-3 text-zinc-600 text-xs mt-1">
                      <span className="text-green-400 font-semibold">{Number(player.wins) || 0}W</span>
                      <span>-</span>
                      <span>{Number(player.races) || 0} races</span>
                    </div>
                  </div>
                  <div className="text-right shrink-0">
                    <div className="text-red-400 font-bold text-lg font-mono">{Number(player.rep) || 0}</div>
                    <div className="text-zinc-600 text-xs uppercase tracking-wider">REP</div>
                  </div>
                </motion.div>
              );
            })}
          </div>
        </>
      )}

      <div className="relative overflow-hidden rounded-xl">
        <div className="absolute inset-0 bg-gradient-to-r from-red-950/50 via-black to-red-950/50" />
        <div className="absolute inset-0 hex-pattern opacity-30" />
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="relative border border-red-900/50 rounded-xl p-5 flex items-center gap-4"
        >
          <div className="w-14 h-14 rounded-xl bg-red-900/40 border border-red-500/30 flex items-center justify-center shadow-lg shadow-red-900/20">
            <TrendingUp size={24} className="text-red-400" />
          </div>
          <div className="flex-1">
            <div className="text-white font-bold text-lg">You</div>
            <div className="text-zinc-500 text-sm flex items-center gap-2">
              <span className="text-red-400 font-semibold">{playerRank ? `Rank #${playerRank}` : 'Unranked'}</span>
              <span>-</span>
              <span className="flex items-center gap-1">
                <Zap size={10} className="text-yellow-500" />
                Finish races to climb
              </span>
            </div>
          </div>
          <div className="text-right">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: 'spring', stiffness: 200 }}
              className="text-red-400 font-bold text-3xl glow-text-red"
            >
              {playerRep}
            </motion.div>
            <div className="text-zinc-600 text-xs uppercase tracking-wider">REP</div>
          </div>
        </motion.div>
      </div>
    </div>
  );
}

function PodiumCard({ player, rank, Icon, height, isGold = false }: {
  player: any;
  rank: number;
  Icon: typeof Trophy;
  height: string;
  isGold?: boolean;
}) {
  const colors = {
    1: 'from-yellow-600/30 via-yellow-900/20 to-black border-yellow-600/50',
    2: 'from-zinc-500/30 via-zinc-700/20 to-black border-zinc-500/40',
    3: 'from-amber-700/30 via-amber-900/20 to-black border-amber-700/40'
  };
  const textColors = {
    1: 'text-yellow-400 glow-text-yellow',
    2: 'text-zinc-300',
    3: 'text-amber-500'
  };
  const iconColors = {
    1: 'text-yellow-400',
    2: 'text-zinc-400',
    3: 'text-amber-600'
  };

  return (
    <div className={`${height} bg-gradient-to-b ${colors[rank as keyof typeof colors] || colors[3]} border rounded-xl p-4 flex flex-col items-center justify-end relative overflow-hidden group hover:scale-[1.02] transition-transform`}>
      {isGold && <div className="absolute inset-0 bg-gradient-to-br from-yellow-400/10 via-transparent to-transparent" />}

      <motion.div
        animate={{ y: [0, -5, 0] }}
        transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
        className="absolute top-3"
      >
        <Icon size={rank === 1 ? 32 : 26} className={iconColors[rank as keyof typeof iconColors] || iconColors[3]} />
      </motion.div>

      <div className="relative z-10 text-center">
        <div className={`text-xl font-bold ${textColors[rank as keyof typeof textColors] || textColors[3]}`}>
          #{rank}
        </div>
        <div className="text-white font-semibold text-sm mt-1 truncate max-w-[120px]">
          {player.name || 'Unknown Racer'}
        </div>
        <div className="text-zinc-500 text-xs font-mono mt-1">
          {Number(player.rep) || 0} REP
        </div>
      </div>
    </div>
  );
}

function getRank(player: any, index: number) {
  return Number(player?.rank) || index + 1;
}
