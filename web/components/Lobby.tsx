import { useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import { X, Users, Flag, Crown, Check, Play, LogOut, Trophy, Zap } from 'lucide-react';
import { fetchNui } from '../hooks/useNui';

interface PlayerData {
  src: number;
  name: string;
  ready: boolean;
  isHost: boolean;
}

interface Route {
  id: string;
  name: string;
  description: string;
  minRep: number;
  entryFee: number;
}

interface LobbyData {
  id: string;
  host: number;
  route: Route;
  betAmount: number;
  prizePool: number;
  players: PlayerData[];
  status: string;
}

interface LobbySummary {
  id: string;
  routeName: string;
  hostName: string;
  playerCount: number;
  maxPlayers: number;
  betAmount: number;
  prizePool: number;
  minRep: number;
}

interface LobbyProps {
  lobbyData: LobbyData | null;
  availableLobbies: LobbySummary[];
  playerRep: number;
  serverId: number | null;
  onClose: () => void;
}

const mockRoutes = [
  { id: 'downtown_drift', name: 'Downtown Drift', description: 'Navigate the city streets', minRep: 0, entryFee: 500 },
  { id: 'harbor_run', name: 'Harbor Run', description: 'Industrial speed run', minRep: 50, entryFee: 1500 },
  { id: 'vinewood_escape', name: 'Vinewood Escape', description: 'Elite hills and curves', minRep: 150, entryFee: 5000 }
];

const maxRep = 500;
const speedLines = Array.from({ length: 12 }, (_, i) => ({
  top: `${8 + i * 8}%`,
  width: `${42 + (i % 4) * 8}%`,
  delay: `${i * 0.3}s`,
  duration: `${2 + (i % 3) * 0.45}s`,
  reverse: i % 3 === 0
}));

const activeSpeedLines = Array.from({ length: 8 }, (_, i) => ({
  top: `${10 + i * 10}%`,
  width: `${34 + (i % 4) * 9}%`,
  delay: `${i * 0.4}s`,
  reverse: i % 2 === 0
}));

export default function Lobby({ lobbyData, availableLobbies, playerRep, serverId, onClose }: LobbyProps) {
  const [view, setView] = useState<'main' | 'create' | 'join'>('main');
  const safeRep = Math.max(0, Number(playerRep) || 0);
  const repPercent = Math.min(100, (safeRep / maxRep) * 100);
  const joinableLobbies = useMemo(() => availableLobbies || [], [availableLobbies]);

  if (lobbyData) {
    return <ActiveLobby lobby={lobbyData} serverId={serverId} onClose={onClose} />;
  }

  return (
    <div className="w-screen h-screen flex items-center justify-center pointer-events-auto">
      <div className="speed-lines-bg">
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
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="racing-panel rounded-xl p-6 max-w-md w-full mx-4 relative"
      >
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3 min-w-0">
            <Zap className="text-red-500 shrink-0" size={28} strokeWidth={2.5} />
            <h1 className="underground-title text-2xl font-bold text-white tracking-wide truncate">
              <span className="text-red-500">UNDERGROUND</span> RACING
            </h1>
          </div>
          <button onClick={onClose} className="text-zinc-500 hover:text-red-500 transition-colors">
            <X size={24} />
          </button>
        </div>

        <div className="mb-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-zinc-400 text-sm uppercase tracking-wider">Street Rep</span>
            <span className="text-red-500 font-bold text-lg flex items-center gap-1">
              <Trophy size={16} className="text-yellow-500" />
              {safeRep} <span className="text-zinc-500 text-sm">/ {maxRep}</span>
            </span>
          </div>
          <div className="rep-bar-container h-3 relative">
            <motion.div
              className="rep-bar-fill h-full"
              initial={{ width: 0 }}
              animate={{ width: `${repPercent}%` }}
              transition={{ duration: 1, ease: 'easeOut' }}
            />
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent" />
          </div>
        </div>

        {view === 'main' && (
          <div className="space-y-3 relative z-10">
            <button
              onClick={() => setView('create')}
              className="btn-create-race w-full text-white py-4 rounded-lg font-bold uppercase tracking-wider flex items-center justify-center gap-3 text-lg"
            >
              <Flag size={22} className="relative z-10" />
              <span className="relative z-10">Create Race</span>
            </button>
            <button
              onClick={() => {
                fetchNui('getLobbies', {}, {});
                setView('join');
              }}
              className="btn-join-race w-full py-4 rounded-lg font-bold uppercase tracking-wider flex items-center justify-center gap-3 text-lg"
            >
              <Users size={22} />
              Join Race
            </button>
            <button
              onClick={() => fetchNui('getLeaderboard', {}, {})}
              className="btn-leaderboard w-full py-4 rounded-lg font-bold uppercase tracking-wider flex items-center justify-center gap-3 text-lg"
            >
              <Trophy size={22} />
              Leaderboard
            </button>
          </div>
        )}

        {view === 'create' && (
          <div>
            <button
              onClick={() => setView('main')}
              className="text-zinc-400 hover:text-red-500 text-sm mb-4 flex items-center gap-1 transition-colors"
            >
              Back
            </button>
            <h3 className="text-lg font-bold text-white mb-4 uppercase tracking-wider">Select Route</h3>
            <div className="space-y-2">
              {mockRoutes.map(route => {
                const locked = safeRep < route.minRep;
                return (
                  <button
                    key={route.id}
                    onClick={() => {
                      if (!locked) {
                        setView('main');
                        fetchNui('createLobby', { routeId: route.id, betAmount: route.entryFee }, {});
                      }
                    }}
                    disabled={locked}
                    className="route-card w-full p-4 rounded-lg text-left"
                  >
                    <div className="flex items-center justify-between gap-4">
                      <div className="min-w-0">
                        <div className="text-white font-bold text-lg truncate">{route.name}</div>
                        <div className="text-zinc-500 text-sm truncate">{route.description}</div>
                      </div>
                      <div className="text-right shrink-0">
                        <div className="text-green-400 font-bold text-lg">${route.entryFee.toLocaleString()}</div>
                        {route.minRep > 0 && (
                          <div className={`text-xs font-semibold ${locked ? 'text-red-500' : 'text-yellow-500'}`}>
                            {locked ? 'LOCKED ' : ''}{route.minRep} REP
                          </div>
                        )}
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {view === 'join' && (
          <div>
            <button
              onClick={() => setView('main')}
              className="text-zinc-400 hover:text-red-500 text-sm mb-4 flex items-center gap-1 transition-colors"
            >
              Back
            </button>
            <h3 className="text-lg font-bold text-white mb-4 uppercase tracking-wider">Available Races</h3>
            {joinableLobbies.length === 0 ? (
              <div className="text-center text-zinc-500 py-8 border border-zinc-800 rounded-lg bg-black/30">
                <Flag size={32} className="mx-auto mb-2 opacity-30" />
                No races available.<br />
                <span className="text-zinc-600 text-sm">Create one to get started!</span>
              </div>
            ) : (
              <div className="space-y-2 max-h-80 overflow-y-auto">
                {joinableLobbies.map(lobby => {
                  const locked = safeRep < (lobby.minRep || 0);
                  const full = (lobby.playerCount || 0) >= (lobby.maxPlayers || 0);
                  return (
                    <button
                      key={lobby.id}
                      onClick={() => fetchNui('joinLobby', { lobbyId: lobby.id }, {})}
                      disabled={locked || full}
                      className="route-card w-full p-4 rounded-lg text-left"
                    >
                      <div className="flex items-center justify-between gap-4">
                        <div className="min-w-0">
                          <div className="text-white font-bold text-lg truncate">{lobby.routeName || 'Unknown Route'}</div>
                          <div className="text-zinc-500 text-sm truncate">Host: {lobby.hostName || 'Unknown'}</div>
                          <div className="text-zinc-600 text-xs mt-1">{lobby.playerCount || 0}/{lobby.maxPlayers || 0} drivers</div>
                        </div>
                        <div className="text-right shrink-0">
                          <div className="text-green-400 font-bold text-lg">${(lobby.prizePool || 0).toLocaleString()}</div>
                          <div className={`text-xs font-semibold ${locked || full ? 'text-red-500' : 'text-yellow-500'}`}>
                            {full ? 'FULL' : locked ? `${lobby.minRep} REP` : `$${(lobby.betAmount || 0).toLocaleString()}`}
                          </div>
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        )}
      </motion.div>
    </div>
  );
}

function ActiveLobby({ lobby, serverId, onClose }: { lobby: LobbyData; serverId: number | null; onClose: () => void }) {
  const players = Array.isArray(lobby.players) ? lobby.players : [];
  const isHost = serverId !== null && players.some(p => p.isHost && p.src === serverId);
  const allReady = players.every(p => p.ready || p.isHost);

  return (
    <div className="w-screen h-screen flex items-center justify-center pointer-events-auto">
      <div className="speed-lines-bg">
        {activeSpeedLines.map((line, i) => (
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
        <div className="flex items-center justify-between mb-4">
          <h2 className="underground-title text-xl font-bold text-white truncate">
            {lobby.route?.name || 'Race Lobby'}
          </h2>
          <button onClick={onClose} className="text-zinc-500 hover:text-red-500 transition-colors">
            <X size={24} />
          </button>
        </div>

        <div className="bg-gradient-to-r from-green-900/30 to-black border border-green-500/40 rounded-lg p-4 mb-4 flex items-center justify-between">
          <span className="text-zinc-400 uppercase text-sm tracking-wider">Prize Pool</span>
          <span className="text-green-400 font-bold text-2xl flex items-center gap-1">
            ${(lobby.prizePool || 0).toLocaleString()}
          </span>
        </div>

        <div className="mb-4">
          <div className="text-zinc-500 text-xs mb-2 uppercase tracking-wider">Drivers ({players.length}/8)</div>
          <div className="space-y-2">
            {players.map((player, i) => (
              <div
                key={`${player.src}-${i}`}
                className={`player-card ${player.ready ? 'ready' : ''} rounded-lg px-4 py-3 flex items-center justify-between`}
              >
                <div className="flex items-center gap-3 min-w-0">
                  {player.isHost && <Crown size={16} className="text-yellow-500 shrink-0" />}
                  <span className="text-white font-semibold truncate max-w-[180px]">{player.name || 'Unknown'}</span>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  {player.ready && <Check size={14} className="text-green-400" />}
                  <span className={`text-xs font-semibold uppercase tracking-wider ${player.ready ? 'text-green-400' : 'text-zinc-500'}`}>
                    {player.ready ? 'Ready' : 'Waiting'}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="space-y-2">
          <button
            onClick={() => fetchNui('toggleReady', {}, {})}
            className="btn-join-race w-full py-3 rounded-lg font-bold uppercase tracking-wider"
          >
            Toggle Ready
          </button>
          {isHost && (
            <button
              onClick={() => fetchNui('startRace', {}, {})}
              disabled={!allReady}
              className="btn-create-race w-full text-white py-3 rounded-lg font-bold uppercase tracking-wider flex items-center justify-center gap-2 disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <Play size={18} className="relative z-10" />
              <span className="relative z-10">Start Race</span>
            </button>
          )}
          <button
            onClick={() => fetchNui('leaveLobby', {}, {})}
            className="w-full bg-red-950/50 hover:bg-red-900/50 border border-red-900/50 text-red-400 py-3 rounded-lg font-bold uppercase tracking-wider transition-all flex items-center justify-center gap-2"
          >
            <LogOut size={18} /> Leave
          </button>
        </div>
      </motion.div>
    </div>
  );
}
