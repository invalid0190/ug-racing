import { useState } from 'react';
import { motion } from 'framer-motion';
import {
  AlertTriangle,
  Check,
  CircleDollarSign,
  Crown,
  Flag,
  Lock,
  LogOut,
  MapPin,
  Play,
  Users,
  Zap
} from 'lucide-react';
import { fetchNui } from '../hooks/useNui';
import type { LobbySummary, RouteSummary } from '../App';

interface PlayerData {
  src: number;
  name: string;
  ready: boolean;
  isHost: boolean;
}

interface LobbyData {
  id: string;
  host: number;
  route: RouteSummary;
  betAmount: number;
  prizePool: number;
  players: PlayerData[];
  status: string;
}

interface LobbyPanelProps {
  lobbyData: LobbyData | null;
  availableLobbies: LobbySummary[];
  routes: RouteSummary[];
  playerRep: number;
  serverId: number | null;
  activeRaceCount: number;
  nearbyPoliceCount: number;
  onNavigate: (tab: 'lobby' | 'routes' | 'leaderboard' | 'stats' | 'network' | 'settings') => void;
}

const betMultipliers = [1, 2, 5];

export default function LobbyPanel({
  lobbyData,
  availableLobbies,
  routes,
  playerRep,
  serverId,
  activeRaceCount,
  nearbyPoliceCount,
  onNavigate
}: LobbyPanelProps) {
  const [view, setView] = useState<'main' | 'create' | 'join'>('main');
  const openLobbies = Array.isArray(availableLobbies) ? availableLobbies : [];
  const routeList = Array.isArray(routes) ? routes : [];

  if (lobbyData) {
    return <ActiveLobbyView lobby={lobbyData} serverId={serverId} />;
  }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-3 gap-4">
        <StatCard icon={CircleDollarSign} label="Available" value={openLobbies.length} hint="races open" color="text-white" />
        <StatCard icon={Zap} label="Racing Now" value={activeRaceCount} hint="active routes" color="text-red-400" />
        <StatCard icon={Crown} label="Your Rep" value={playerRep} hint="street rank" color="text-yellow-400" />
      </div>

      {view === 'main' && (
        <div className="space-y-4">
          <motion.button
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.99 }}
            onClick={() => setView('create')}
            className="btn-create-race w-full py-6 rounded-xl font-bold uppercase tracking-wider flex items-center justify-center gap-3 text-lg relative overflow-hidden"
          >
            <div className="absolute inset-0 racing-stripe-bg opacity-30" />
            <Flag size={24} className="relative z-10" />
            <span className="relative z-10">Create Race</span>
          </motion.button>

          <motion.button
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.99 }}
            onClick={() => {
              fetchNui('getLobbies', {}, { success: true });
              setView('join');
            }}
            className="btn-join-race w-full py-6 rounded-xl font-bold uppercase tracking-wider flex items-center justify-center gap-3 text-lg"
          >
            <Users size={24} />
            <span>Join Race</span>
            <span className="ml-auto mr-4 bg-red-900/40 text-red-400 px-3 py-1 rounded-lg text-sm font-bold">
              {openLobbies.length} OPEN
            </span>
          </motion.button>

          <div className="grid grid-cols-2 gap-3 pt-2">
            <button
              onClick={() => onNavigate('routes')}
              className="glass-dark border border-zinc-800 hover:border-red-600/50 py-4 rounded-xl text-zinc-400 hover:text-white transition-all flex items-center justify-center gap-2"
            >
              <Flag size={18} />
              <span className="text-sm font-semibold">Browse Routes</span>
            </button>
            <button
              onClick={() => onNavigate('leaderboard')}
              className="glass-dark border border-zinc-800 hover:border-yellow-600/50 py-4 rounded-xl text-zinc-400 hover:text-yellow-400 transition-all flex items-center justify-center gap-2"
            >
              <Crown size={18} />
              <span className="text-sm font-semibold">Leaderboard</span>
            </button>
          </div>

          {nearbyPoliceCount > 0 && (
            <div className="flex items-center gap-3 bg-red-950/20 border border-red-900/30 rounded-lg px-4 py-3">
              <AlertTriangle size={16} className="text-red-400" />
              <span className="text-zinc-400 text-sm">
                <span className="text-red-400 font-semibold">{nearbyPoliceCount}</span> police near active routes
              </span>
            </div>
          )}
        </div>
      )}

      {view === 'create' && (
        <div className="space-y-4">
          <button
            onClick={() => setView('main')}
            className="text-zinc-500 hover:text-red-400 text-sm flex items-center gap-1 transition-colors"
          >
            &lt; Back to Main
          </button>

          <h3 className="text-lg font-bold text-white uppercase tracking-wider flex items-center gap-2">
            <Flag size={20} className="text-red-500" />
            Select Route
          </h3>

          {routeList.length === 0 ? (
            <EmptyState icon={Flag} title="No routes loaded" description="Server route data is not available yet." />
          ) : (
            <div className="space-y-3">
              {routeList.map(route => {
                const locked = playerRep < route.minRep;
                return (
                  <div key={route.id} className="route-card p-4 rounded-lg border border-zinc-800 bg-black/30">
                    <div className="flex items-start justify-between mb-3 gap-4">
                      <div className="min-w-0">
                        <h4 className="text-white font-bold text-lg flex items-center gap-2">
                          <span className="truncate">{route.name}</span>
                          {locked && <Lock size={14} className="text-red-500 shrink-0" />}
                        </h4>
                        <p className="text-zinc-500 text-sm">{route.description}</p>
                      </div>
                      <div className="text-right shrink-0">
                        <div className="text-green-400 font-bold text-lg">${route.entryFee.toLocaleString()}</div>
                        {route.minRep > 0 && (
                          <div className={`text-xs font-semibold ${locked ? 'text-red-400' : 'text-yellow-500'}`}>
                            {route.minRep} REP REQ
                          </div>
                        )}
                      </div>
                    </div>

                    {!locked && (
                      <div className="flex gap-2">
                        {betMultipliers.map(mult => (
                          <button
                            key={mult}
                            onClick={() => {
                              fetchNui('createLobby', { routeId: route.id, betAmount: route.entryFee * mult }, { success: true });
                              setView('main');
                            }}
                            className={`flex-1 py-2 rounded text-sm font-bold transition-all ${
                              mult === 5
                                ? 'bg-red-900/40 border border-red-500/40 text-red-400 hover:bg-red-800/50'
                                : 'bg-zinc-900 border border-zinc-700 text-zinc-300 hover:border-zinc-500'
                            }`}
                          >
                            {mult}x - ${(route.entryFee * mult).toLocaleString()}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {view === 'join' && (
        <div className="space-y-4">
          <button
            onClick={() => setView('main')}
            className="text-zinc-500 hover:text-red-400 text-sm flex items-center gap-1 transition-colors"
          >
            &lt; Back to Main
          </button>

          <h3 className="text-lg font-bold text-white uppercase tracking-wider flex items-center gap-2">
            <Users size={20} className="text-red-500" />
            Available Races
          </h3>

          {openLobbies.length === 0 ? (
            <EmptyState icon={Flag} title="No races available" description="Create one to get started." />
          ) : (
            <div className="space-y-3">
              {openLobbies.map(race => {
                const canJoin = playerRep >= (race.minRep || 0);
                const spotsLeft = (race.maxPlayers || 0) - (race.playerCount || 0);
                return (
                  <div
                    key={race.id}
                    className={`route-card p-4 rounded-lg border ${canJoin ? 'border-zinc-800' : 'border-red-900/30 opacity-50'}`}
                  >
                    <div className="flex items-center justify-between mb-2 gap-3">
                      <h4 className="text-white font-bold text-lg truncate">{race.routeName || 'Unknown Route'}</h4>
                      <span className="text-green-400 font-bold shrink-0">${(race.prizePool || 0).toLocaleString()}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-zinc-500">Host: <span className="text-zinc-300">{race.hostName || 'Unknown'}</span></span>
                      <span className="text-zinc-500">
                        <Users size={12} className="inline mr-1" />
                        {race.playerCount || 0}/{race.maxPlayers || 0}
                      </span>
                    </div>
                    <button
                      disabled={!canJoin || spotsLeft <= 0}
                      onClick={() => {
                        fetchNui('joinLobby', { lobbyId: race.id }, { success: true });
                        setView('main');
                      }}
                      className={`w-full mt-3 py-2 rounded font-bold text-sm transition-all ${
                        canJoin && spotsLeft > 0
                          ? 'bg-red-900/40 border border-red-500/40 text-red-400 hover:bg-red-800/50'
                          : 'bg-zinc-900 border border-zinc-800 text-zinc-600 cursor-not-allowed'
                      }`}
                    >
                      {!canJoin ? `${race.minRep} REP REQUIRED` : spotsLeft <= 0 ? 'FULL' : 'JOIN RACE'}
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function ActiveLobbyView({ lobby, serverId }: { lobby: LobbyData; serverId: number | null }) {
  const players = Array.isArray(lobby.players) ? lobby.players : [];
  const isHost = players.some(p => p.isHost && p.src === serverId);
  const allReady = players.filter(p => !p.isHost).every(p => p.ready);
  const canStart = players.length >= 2 && allReady;

  return (
    <div className="space-y-6">
      <div className="bg-gradient-to-r from-red-950/30 via-black to-red-950/30 border border-red-900/40 rounded-lg p-5">
        <div className="flex items-center justify-between gap-4">
          <div className="min-w-0">
            <h2 className="text-2xl font-bold text-white truncate">{lobby.route?.name || 'Race Lobby'}</h2>
            <p className="text-zinc-500 text-sm">{lobby.route?.description || 'Waiting for racers'}</p>
          </div>
          <div className="text-right shrink-0">
            <div className="text-zinc-500 text-xs uppercase tracking-wider">Prize Pool</div>
            <div className="text-green-400 font-bold text-2xl">${(lobby.prizePool || 0).toLocaleString()}</div>
          </div>
        </div>
      </div>

      <div>
        <h3 className="text-zinc-400 text-xs uppercase tracking-wider mb-3 flex items-center gap-2">
          <Users size={14} />
          Drivers ({players.length}/8)
        </h3>
        <div className="grid grid-cols-2 gap-3">
          {players.map((player) => (
            <div
              key={player.src}
              className={`player-card ${player.ready ? 'ready' : ''} rounded-lg px-4 py-3 flex items-center justify-between`}
            >
              <div className="flex items-center gap-3 min-w-0">
                <div className={`w-2 h-2 rounded-full shrink-0 ${player.ready ? 'bg-green-500' : 'bg-zinc-600'}`} />
                <span className="text-white font-semibold truncate">{player.name || 'Unknown'}</span>
                {player.isHost && <Crown size={14} className="text-yellow-500 shrink-0" />}
              </div>
              <span className={`text-xs font-bold uppercase shrink-0 ${player.ready ? 'text-green-400' : 'text-zinc-600'}`}>
                {player.ready ? 'READY' : 'WAIT'}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="mb-3">
        <button
          onClick={() => fetchNui('setWaypoint', {}, { success: true })}
          className="w-full py-3 rounded-lg font-bold uppercase tracking-wider text-sm flex items-center justify-center gap-2 bg-blue-950/40 border border-blue-500/40 text-blue-400 hover:bg-blue-900/40 transition-all"
        >
          <MapPin size={16} />
          Set Waypoint to Start Line
        </button>
      </div>

      <div className={`grid gap-3 ${isHost ? 'grid-cols-2' : 'grid-cols-3'}`}>
        <button
          onClick={() => fetchNui('toggleReady', {}, { success: true })}
          className="btn-join-race py-3 rounded-lg font-bold uppercase tracking-wider text-sm flex items-center justify-center gap-2"
        >
          <Check size={16} />
          Toggle Ready
        </button>
        {isHost ? (
          <button
            disabled={!canStart}
            onClick={() => fetchNui('startRace', {}, { success: true })}
            className={`py-3 rounded-lg font-bold uppercase tracking-wider text-sm flex items-center justify-center gap-2 ${
              canStart
                ? 'btn-create-race text-white'
                : 'bg-zinc-900 border border-zinc-800 text-zinc-600 cursor-not-allowed'
            }`}
          >
            <Play size={16} />
            Start Race
          </button>
        ) : (
          <button
            onClick={() => fetchNui('leaveLobby', {}, { success: true })}
            className="bg-red-950/40 border border-red-900/40 text-red-400 py-3 rounded-lg font-bold uppercase tracking-wider text-sm flex items-center justify-center gap-2 hover:bg-red-900/40"
          >
            <LogOut size={16} />
            Leave
          </button>
        )}
      </div>

      {isHost && !canStart && (
        <p className="text-center text-zinc-600 text-sm">
          Waiting for all players to be ready. All racers must be near the start line.
        </p>
      )}
    </div>
  );
}

function StatCard({ icon: Icon, label, value, hint, color }: {
  icon: typeof Flag;
  label: string;
  value: number;
  hint: string;
  color: string;
}) {
  return (
    <motion.div
      whileHover={{ scale: 1.02, y: -2 }}
      className="stat-card hover-lift glass-dark border border-zinc-800 rounded-xl p-4 relative overflow-hidden"
    >
      <div className="relative">
        <div className="text-zinc-500 text-xs uppercase tracking-wider mb-1 flex items-center gap-1">
          <Icon size={12} />
          {label}
        </div>
        <div className={`text-3xl font-bold ${color}`}>{value}</div>
        <div className="text-zinc-500/70 text-xs mt-1">{hint}</div>
      </div>
    </motion.div>
  );
}

function EmptyState({ icon: Icon, title, description }: {
  icon: typeof Flag;
  title: string;
  description: string;
}) {
  return (
    <div className="text-center text-zinc-500 py-12 border border-zinc-800 rounded-lg bg-black/30">
      <Icon size={40} className="mx-auto mb-3 opacity-30" />
      <p className="text-lg">{title}</p>
      <p className="text-zinc-600 text-sm mt-1">{description}</p>
    </div>
  );
}
