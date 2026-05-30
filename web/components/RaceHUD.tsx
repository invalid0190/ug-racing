import { motion } from 'framer-motion';
import { Flag, Gauge, Users, AlertTriangle, Siren } from 'lucide-react';

interface PlayerData {
  id?: string;
  serverId?: number;
  name: string;
  position?: number;
  finished?: boolean;
  checkpoint?: number;
  totalCheckpoints?: number;
}

interface RaceHUDProps {
  currentCheckpoint: number;
  totalCheckpoints: number;
  speed: number;
  position: number;
  totalPlayers: number;
  players: PlayerData[];
  policeWarning: boolean;
  hudOpacity?: number;
}

export default function RaceHUD({ currentCheckpoint, totalCheckpoints, speed, position, totalPlayers, players, policeWarning, hudOpacity = 100 }: RaceHUDProps) {
  const safeTotal = Math.max(1, Number(totalCheckpoints) || 1);
  const safeCurrent = Math.min(safeTotal, Math.max(0, Number(currentCheckpoint) || 0));
  const safePlayers = Array.isArray(players) ? players : [];
  const sortedPlayers = [...safePlayers].sort((a, b) => {
    const posA = Number(a.position) || 999;
    const posB = Number(b.position) || 999;
    return posA - posB;
  });
  const progress = Math.min(100, (safeCurrent / safeTotal) * 100);
  const safeOpacity = Math.max(0.3, Math.min(1, (Number(hudOpacity) || 100) / 100));

  return (
    <div className="w-screen h-screen relative pointer-events-auto" style={{ opacity: safeOpacity }}>
      {/* Speed & position stay centered so they do not cover the GTA minimap. */}
      <div className="absolute bottom-8 left-1/2 -translate-x-1/2">
        <motion.div
          initial={{ y: 80, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="flex gap-3"
        >
          <div className="race-hud-panel rounded-lg px-4 py-3 min-w-[118px] border-l-4 border-l-red-600">
            <div className="flex items-center gap-2 text-red-500 text-xs mb-1 uppercase tracking-wider font-semibold">
              <Gauge size={14} />
              <span>Speed</span>
            </div>
            <div className="text-white font-bold text-3xl font-mono tracking-tight leading-none">
              {Math.max(0, Number(speed) || 0)}
            </div>
            <div className="text-zinc-600 text-xs uppercase">mph</div>
          </div>

          <div className="race-hud-panel rounded-lg px-4 py-3 min-w-[96px] border-l-4 border-l-orange-500">
            <div className="flex items-center gap-2 text-orange-500 text-xs mb-1 uppercase tracking-wider font-semibold">
              <Flag size={14} />
              <span>Pos</span>
            </div>
            <div className="text-white font-bold text-3xl font-mono tracking-tight leading-none">
              {Math.max(1, Number(position) || 1)}<span className="text-lg text-zinc-600">/{Math.max(1, Number(totalPlayers) || 1)}</span>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Checkpoint Progress - Top Center */}
      <motion.div
        initial={{ y: -100, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="absolute top-6 left-1/2 -translate-x-1/2"
      >
        <div className="race-hud-panel rounded-lg px-6 py-3 border-t-2 border-t-yellow-500">
          <div className="flex items-center gap-3 text-yellow-500 text-sm mb-2 uppercase tracking-wider font-semibold">
            <Flag size={16} />
            <span>Checkpoint {safeCurrent}/{safeTotal}</span>
          </div>
          <div className="w-72 h-2.5 bg-black/80 rounded-full overflow-hidden border border-zinc-800">
            <motion.div
              className="h-full bg-gradient-to-r from-yellow-600 via-yellow-500 to-orange-500"
              initial={{ width: 0 }}
              animate={{ width: `${progress}%` }}
              transition={{ duration: 0.3 }}
              style={{
                boxShadow: '0 0 15px rgba(234, 179, 8, 0.5)'
              }}
            />
          </div>
        </div>
      </motion.div>

      {/* Leaderboard - Top Right */}
      <motion.div
        initial={{ x: 200, opacity: 0 }}
        animate={{ x: 0, opacity: 1 }}
        className="absolute top-6 right-6"
      >
        <div className="race-hud-panel rounded-lg p-3 min-w-[180px] border-r-2 border-r-zinc-600">
          <div className="flex items-center gap-2 text-zinc-500 text-xs mb-2 border-b border-zinc-800 pb-2 uppercase tracking-wider font-semibold">
            <Users size={14} />
            <span>Live Standings</span>
          </div>
          <div className="space-y-1.5">
            {sortedPlayers.slice(0, 4).map((player, i) => {
              const playerPosition = Math.max(1, Number(player.position) || i + 1);
              return (
              <div
                key={`${player.id || player.serverId || player.name || 'racer'}-${i}`}
                className={`flex items-center justify-between text-sm ${player.finished ? 'text-green-400' : 'text-zinc-400'}`}
              >
                <span className="flex items-center gap-2">
                  <span className={`font-bold w-5 ${
                    playerPosition === 1 ? 'text-yellow-500' :
                    playerPosition === 2 ? 'text-zinc-300' :
                    playerPosition === 3 ? 'text-amber-600' :
                    'text-zinc-600'
                  }`}>
                    #{playerPosition}
                  </span>
                  <span className="truncate max-w-[90px]">{player.name || 'Unknown'}</span>
                </span>
                {player.finished ? (
                  <span className="text-xs text-green-500 uppercase font-semibold">Done</span>
                ) : player.checkpoint !== undefined && (
                  <span className="text-[10px] text-zinc-600 font-mono">
                    {Math.max(0, Number(player.checkpoint) || 0)}/{Math.max(1, Number(player.totalCheckpoints) || safeTotal)}
                  </span>
                )}
              </div>
              );
            })}
          </div>
        </div>
      </motion.div>

      {/* Police Warning */}
      {policeWarning && (
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-50"
        >
          <div className="police-warning rounded-xl px-10 py-5 flex items-center gap-4">
            <Siren className="text-white animate-pulse" size={40} />
            <div>
              <div className="text-white font-bold text-2xl uppercase tracking-wider">Police Nearby!</div>
              <div className="text-red-200 text-sm uppercase">Stay alert and evade</div>
            </div>
          </div>
        </motion.div>
      )}
    </div>
  );
}
