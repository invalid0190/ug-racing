import { motion } from 'framer-motion';
import { Trophy, X, Crown, Medal, Award } from 'lucide-react';

interface LeaderboardProps {
  data: Array<{ name: string; rep: number }>;
  playerRep: number;
  onClose: () => void;
}

const maxRep = 500;
const speedLines = Array.from({ length: 8 }, (_, i) => ({
  top: `${10 + i * 10}%`,
  width: `${34 + (i % 4) * 9}%`,
  delay: `${i * 0.4}s`,
  reverse: i % 2 === 0
}));

export default function Leaderboard({ data, playerRep, onClose }: LeaderboardProps) {
  const safeData = Array.isArray(data) ? data : [];
  const safeRep = Math.max(0, Number(playerRep) || 0);
  const repPercent = Math.min(100, (safeRep / maxRep) * 100);

  return (
    <div className="w-screen h-screen flex items-center justify-center pointer-events-auto">
      {/* Speed Lines Background */}
      <div className="speed-lines-bg">
        {speedLines.map((line, i) => (
          <div
            key={i}
            className={`speed-line ${line.reverse ? 'reverse' : ''}`}
            style={{
              top: line.top,
              width: line.width,
              animationDelay: line.delay
            }}
          />
        ))}
      </div>

      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="racing-panel rounded-xl p-6 max-w-md w-full mx-4 relative"
      >
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <Trophy className="text-yellow-500" size={28} />
            <h2 className="text-xl font-bold text-white uppercase tracking-wider">
              Street <span className="text-yellow-500">Legends</span>
            </h2>
          </div>
          <button onClick={onClose} className="text-zinc-500 hover:text-red-500 transition-colors">
            <X size={24} />
          </button>
        </div>

        {/* Your Rep */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-zinc-400 text-sm uppercase tracking-wider">Your Reputation</span>
            <span className="text-yellow-500 font-bold text-lg flex items-center gap-1">
              {safeRep} <span className="text-zinc-600 text-sm">/ {maxRep}</span>
            </span>
          </div>
          <div className="rep-bar-container h-2.5 relative">
            <motion.div
              className="rep-bar-fill h-full"
              initial={{ width: 0 }}
              animate={{ width: `${repPercent}%` }}
              transition={{ duration: 1, ease: 'easeOut' }}
              style={{
                background: 'linear-gradient(90deg, #92400e, #d97706, #fbbf24)'
              }}
            />
          </div>
        </div>

        {/* Top 3 Podium */}
        <div className="flex justify-center items-end gap-3 mb-6">
          {/* 2nd Place */}
          {safeData[1] && (
            <motion.div
              initial={{ y: 50, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.2 }}
              className="flex flex-col items-center"
            >
              <div className="text-zinc-300 font-bold text-sm mb-1 truncate w-16 text-center">{safeData[1].name || 'Unknown'}</div>
              <div className="text-zinc-500 text-xs mb-2">{safeData[1].rep || 0} REP</div>
              <div className="w-16 h-16 bg-gradient-to-t from-zinc-700 to-zinc-500 rounded-t-lg flex items-center justify-center">
                <Medal className="text-zinc-300" size={24} />
              </div>
              <div className="text-zinc-400 font-bold text-lg mt-1">2</div>
            </motion.div>
          )}

          {/* 1st Place */}
          {safeData[0] && (
            <motion.div
              initial={{ y: 50, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="flex flex-col items-center"
            >
              <div className="text-yellow-500 font-bold text-sm mb-1 truncate w-16 text-center">{safeData[0].name || 'Unknown'}</div>
              <div className="text-yellow-600 text-xs mb-2">{safeData[0].rep || 0} REP</div>
              <div className="w-16 h-20 bg-gradient-to-t from-yellow-700 to-yellow-500 rounded-t-lg flex items-center justify-center shadow-[0_0_30px_rgba(234,179,8,0.4)]">
                <Crown className="text-white" size={28} />
              </div>
              <div className="text-yellow-500 font-bold text-xl mt-1">1</div>
            </motion.div>
          )}

          {/* 3rd Place */}
          {safeData[2] && (
            <motion.div
              initial={{ y: 50, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.3 }}
              className="flex flex-col items-center"
            >
              <div className="text-amber-600 font-bold text-sm mb-1 truncate w-16 text-center">{safeData[2].name || 'Unknown'}</div>
              <div className="text-amber-700 text-xs mb-2">{safeData[2].rep || 0} REP</div>
              <div className="w-16 h-14 bg-gradient-to-t from-amber-800 to-amber-600 rounded-t-lg flex items-center justify-center">
                <Award className="text-amber-200" size={22} />
              </div>
              <div className="text-amber-600 font-bold text-lg mt-1">3</div>
            </motion.div>
          )}
        </div>

        {/* Rest of Leaderboard */}
        <div className="space-y-2 max-h-40 overflow-y-auto">
          {safeData.length === 0 && (
            <div className="text-center text-zinc-500 py-8 border border-zinc-800 rounded-lg bg-black/30">
              No racers ranked yet.
            </div>
          )}
          {safeData.slice(3).map((entry, i) => (
            <motion.div
              key={`${entry.name || 'racer'}-${i}`}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: 0.4 + i * 0.05 }}
              className="flex items-center justify-between p-3 rounded-lg bg-black/40 border border-zinc-800/50"
            >
              <div className="flex items-center gap-3">
                <span className="text-zinc-600 font-bold w-6">{i + 4}</span>
                <span className="text-zinc-300">{entry.name || 'Unknown'}</span>
              </div>
              <span className="text-yellow-500 font-semibold">
                {entry.rep || 0} REP
              </span>
            </motion.div>
          ))}
        </div>

        {/* Back Button */}
        <button
          onClick={onClose}
          className="btn-leaderboard w-full mt-5 py-3 rounded-lg font-bold uppercase tracking-wider"
        >
          Back
        </button>
      </motion.div>
    </div>
  );
}
