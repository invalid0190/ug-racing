import { motion } from 'framer-motion';
import {
  Activity,
  Circle,
  Flag,
  Headphones,
  LogIn,
  LogOut,
  MessageCircle,
  Radio,
  RefreshCw,
  ShieldAlert,
  Signal,
  UserPlus,
  Users,
  Wifi
} from 'lucide-react';
import { fetchNui } from '../hooks/useNui';
import type { NetworkData } from '../App';

interface NetworkPanelProps {
  data: NetworkData;
  serverId: number | null;
}

type RaceRadioData = NonNullable<NetworkData['radio']>;

const statusColors = {
  racing: 'text-red-400',
  lobby: 'text-green-400',
  idle: 'text-zinc-500'
};

export default function NetworkPanel({ data, serverId }: NetworkPanelProps) {
  const racers = Array.isArray(data?.racers) ? data.racers : [];
  const onlineCount = Number(data?.onlineCount) || racers.length;
  const lobbyCount = Number(data?.lobbyCount) || 0;
  const activeRaceCount = Number(data?.activeRaceCount) || 0;
  const nearbyPoliceCount = Number(data?.nearbyPoliceCount) || 0;
  const radio = data?.radio;

  const refreshNetwork = () => {
    void fetchNui('getNetwork', {}, { success: true });
    void fetchNui('getRaceRadio', {}, { success: true });
  };

  const toggleRaceRadio = () => {
    const eventName = radio?.joined ? 'raceRadioLeave' : 'raceRadioJoin';
    void fetchNui(eventName, {}, { success: true }).then(refreshNetwork);
  };

  return (
    <div className="h-full flex flex-col gap-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-3">
            <Radio size={24} className="text-red-400" />
            Network Hub
          </h2>
          <p className="text-zinc-500 text-sm mt-1">Live racers, lobbies, and race activity</p>
        </div>
        <button
          onClick={refreshNetwork}
          className="flex items-center gap-2 bg-black/40 border border-zinc-800 rounded px-3 py-2 text-zinc-400 hover:text-zinc-200 hover:border-zinc-700 transition-all shrink-0"
        >
          <RefreshCw size={14} />
          Refresh
        </button>
      </div>

      <div className="grid grid-cols-4 gap-3">
        <NetworkMetric label="Racers Online" value={onlineCount} />
        <NetworkMetric label="Open Lobbies" value={lobbyCount} />
        <NetworkMetric label="Active Races" value={activeRaceCount} />
        <NetworkMetric label="Police Nearby" value={nearbyPoliceCount} danger={nearbyPoliceCount > 0} />
      </div>

      <div className="flex-1 grid grid-cols-[0.95fr_1.05fr] gap-6 min-h-0">
        <div className="flex min-h-0 flex-col gap-4">
          <CrewRadioCard radio={radio} onToggle={toggleRaceRadio} />

          <div className="bg-black/40 border border-zinc-800 rounded-lg p-5 flex flex-1 flex-col min-h-0">
            <h3 className="text-lg font-semibold text-white flex items-center gap-2 mb-4">
              <Signal size={18} className="text-red-400" />
              Server Activity
            </h3>

            <div className="space-y-3">
              <ActivityRow
                icon={Wifi}
                label="Connection"
                value={onlineCount > 0 ? 'Online' : 'Waiting'}
                tone={onlineCount > 0 ? 'green' : 'zinc'}
              />
              <ActivityRow
                icon={Flag}
                label="Race Board"
                value={`${lobbyCount} open / ${activeRaceCount} active`}
                tone={activeRaceCount > 0 ? 'red' : 'zinc'}
              />
              <ActivityRow
                icon={ShieldAlert}
                label="Police Scan"
                value={nearbyPoliceCount > 0 ? `${nearbyPoliceCount} nearby` : 'Clear'}
                tone={nearbyPoliceCount > 0 ? 'red' : 'green'}
              />
            </div>

            <div className="mt-auto grid grid-cols-3 gap-3 pt-5">
              <StatusPill label="Racing" value={racers.filter((racer) => racer.status === 'racing').length} tone="red" />
              <StatusPill label="Lobby" value={racers.filter((racer) => racer.status === 'lobby').length} tone="green" />
              <StatusPill label="Idle" value={racers.filter((racer) => racer.status === 'idle').length} tone="zinc" />
            </div>
          </div>
        </div>

        <div className="bg-black/40 border border-zinc-800 rounded-lg p-5 flex flex-col min-h-0">
          <h3 className="text-lg font-semibold text-white flex items-center gap-2 mb-4">
            <Users size={18} className="text-red-400" />
            Online Racers
          </h3>

          {racers.length === 0 ? (
            <div className="flex-1 flex flex-col items-center justify-center text-zinc-600 border border-zinc-800 rounded-lg bg-black/20">
              <Users size={38} className="mb-3 opacity-40" />
              <span>No racers online</span>
            </div>
          ) : (
            <div className="flex-1 overflow-y-auto space-y-2 pr-2">
              {racers.map((racer) => {
                const isSelf = serverId !== null && String(racer.id) === String(serverId);

                return (
                  <motion.div
                    key={racer.id}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    className="flex items-center justify-between p-3 bg-zinc-900/40 border border-zinc-800 rounded hover:border-zinc-700 transition-all"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="relative shrink-0">
                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-zinc-700 to-zinc-800 flex items-center justify-center">
                          <span className="text-xs font-bold text-zinc-400">
                            {(racer.name || '?').charAt(0)}
                          </span>
                        </div>
                        <Circle
                          size={10}
                          className={`absolute -bottom-0.5 -right-0.5 ${statusColors[racer.status] || statusColors.idle} fill-current`}
                        />
                      </div>
                      <div className="min-w-0">
                        <span className="text-zinc-200 font-medium truncate block">{racer.name || 'Unknown Racer'}</span>
                        <div className="flex items-center gap-2">
                          <span className={`text-xs ${statusColors[racer.status] || statusColors.idle}`}>
                            {(racer.status || 'idle').toUpperCase()}
                          </span>
                          <span className="text-zinc-600 text-xs">- {Number(racer.rep) || 0} REP</span>
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      {isSelf ? (
                        <span className="rounded border border-red-900/50 bg-red-950/30 px-2 py-1 text-xs text-red-300">You</span>
                      ) : (
                        <>
                          {racer.inVoice && <Wifi size={14} className="text-green-400" />}
                          <button
                            onClick={() => fetchNui('networkMessage', { targetId: racer.id }, { success: true })}
                            aria-label={`Message ${racer.name}`}
                            className="p-1.5 rounded bg-zinc-800 text-zinc-500 hover:text-zinc-300 hover:bg-zinc-700 transition-all"
                          >
                            <MessageCircle size={14} />
                          </button>
                          <button
                            onClick={() => fetchNui('networkInvite', { targetId: racer.id }, { success: true })}
                            aria-label={`Invite ${racer.name}`}
                            className="p-1.5 rounded bg-zinc-800 text-zinc-500 hover:text-green-400 hover:bg-zinc-700 transition-all"
                          >
                            <UserPlus size={14} />
                          </button>
                        </>
                      )}
                    </div>
                  </motion.div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function CrewRadioCard({ radio, onToggle }: { radio?: RaceRadioData; onToggle: () => void }) {
  const channel = Math.max(0, Number(radio?.channel) || 0);
  const crewCount = Math.max(0, Number(radio?.crewCount) || 0);
  const joined = radio?.joined === true;
  const enabled = radio?.enabled !== false;
  const available = enabled && radio?.available === true;
  const inLobby = radio?.inLobby === true;
  const canUse = available && inLobby && channel > 0;
  const status = !enabled
    ? 'Disabled'
    : !available
      ? `${radio?.voiceResource || 'Voice'} offline`
      : !inLobby
        ? 'Join a lobby first'
        : joined
          ? 'Crew connected'
          : 'Ready for crew';
  const buttonLabel = joined ? 'Leave Radio' : 'Join Crew';
  const ButtonIcon = joined ? LogOut : LogIn;

  return (
    <div className={`rounded-lg border p-4 ${joined ? 'border-green-800/60 bg-green-950/10' : 'border-red-900/40 bg-black/40'}`}>
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0">
          <h3 className="flex items-center gap-2 text-lg font-semibold text-white">
            <Headphones size={18} className={joined ? 'text-green-400' : 'text-red-400'} />
            Crew Radio
          </h3>
          <p className={`mt-1 text-sm ${joined ? 'text-green-300' : canUse ? 'text-zinc-400' : 'text-zinc-600'}`}>
            {status}
          </p>
        </div>
        <div className={`rounded border px-3 py-2 text-right ${joined ? 'border-green-900/60 bg-green-950/20' : 'border-zinc-800 bg-zinc-950/60'}`}>
          <div className="text-[10px] uppercase tracking-[0.18em] text-zinc-500">Channel</div>
          <div className={`text-base font-bold ${channel > 0 ? 'text-white' : 'text-zinc-600'}`}>
            {channel > 0 ? `${channel}.0` : '--'}
          </div>
        </div>
      </div>

      <div className="mt-4 grid grid-cols-[1fr_auto] gap-3">
        <div className="rounded border border-zinc-800 bg-zinc-950/60 px-3 py-2">
          <div className="text-[10px] uppercase tracking-[0.16em] text-zinc-500">Crew Online</div>
          <div className="mt-1 flex items-center gap-2 text-zinc-200">
            <Wifi size={14} className={crewCount > 0 ? 'text-green-400' : 'text-zinc-600'} />
            <span className="font-semibold">{crewCount}</span>
            <span className="text-xs text-zinc-500">on race radio</span>
          </div>
        </div>

        <button
          type="button"
          disabled={!canUse}
          onClick={onToggle}
          className={`flex min-w-[122px] items-center justify-center gap-2 rounded border px-4 py-2 text-sm font-bold uppercase transition-all ${
            joined
              ? 'border-red-800/70 bg-red-950/30 text-red-200 hover:bg-red-900/40'
              : canUse
                ? 'border-green-800/70 bg-green-950/20 text-green-300 hover:bg-green-900/30'
                : 'cursor-not-allowed border-zinc-800 bg-zinc-950/40 text-zinc-600'
          }`}
        >
          <ButtonIcon size={15} />
          {buttonLabel}
        </button>
      </div>
    </div>
  );
}

function NetworkMetric({ label, value, danger = false }: { label: string; value: number; danger?: boolean }) {
  return (
    <div className={`bg-black/40 border ${danger ? 'border-red-800/60' : 'border-zinc-800'} rounded-lg p-3`}>
      <div className="text-zinc-500 text-xs uppercase">{label}</div>
      <div className={`text-2xl font-bold ${danger ? 'text-red-400' : 'text-white'}`}>{value}</div>
    </div>
  );
}

function ActivityRow({ icon: Icon, label, value, tone }: {
  icon: typeof Activity;
  label: string;
  value: string;
  tone: 'green' | 'red' | 'zinc';
}) {
  const toneClass = tone === 'green' ? 'text-green-400' : tone === 'red' ? 'text-red-400' : 'text-zinc-400';

  return (
    <div className="flex items-center justify-between gap-3 rounded-lg border border-zinc-800 bg-zinc-950/60 px-4 py-3">
      <div className="flex items-center gap-3 text-zinc-400">
        <Icon size={17} className={toneClass} />
        <span>{label}</span>
      </div>
      <span className={`font-semibold ${toneClass}`}>{value}</span>
    </div>
  );
}

function StatusPill({ label, value, tone }: { label: string; value: number; tone: 'green' | 'red' | 'zinc' }) {
  const toneClass = tone === 'green' ? 'text-green-400 border-green-900/50' : tone === 'red' ? 'text-red-400 border-red-900/50' : 'text-zinc-400 border-zinc-800';

  return (
    <div className={`rounded-lg border bg-black/30 p-3 text-center ${toneClass}`}>
      <div className="text-xl font-bold">{value}</div>
      <div className="text-xs text-zinc-500 uppercase">{label}</div>
    </div>
  );
}
