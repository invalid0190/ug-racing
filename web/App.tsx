import { useCallback, useEffect, useRef, useState } from 'react';
import { AnimatePresence } from 'framer-motion';
import { isDebug, useNuiEvent, fetchNui } from './hooks/useNui';
import RaceHUD from './components/RaceHUD';
import Countdown from './components/Countdown';
import Results from './components/Results';
import TabletDashboard from './components/TabletDashboard';

type Screen = 'none' | 'tablet' | 'racehud' | 'countdown' | 'results';

interface PlayerData {
  name: string;
  position?: number;
  finished?: boolean;
}

interface RaceState {
  currentCheckpoint: number;
  totalCheckpoints: number;
  speed: number;
  position: number;
  totalPlayers: number;
  players: PlayerData[];
  policeWarning: boolean;
}

interface ResultItem {
  name: string;
  position: number;
  repGained: number;
  prizeWon?: number;
  time?: number;
  dnf?: boolean;
}

interface ResultsData {
  results: ResultItem[];
  prizePool: number;
  reason?: string;
}

export interface LobbySummary {
  id: string;
  routeName: string;
  hostName: string;
  playerCount: number;
  maxPlayers: number;
  betAmount: number;
  prizePool: number;
  minRep: number;
}

export interface RouteSummary {
  id: string;
  name: string;
  description: string;
  minRep: number;
  entryFee: number;
  checkpointCount: number;
  estimatedTime?: string;
  difficulty?: string;
  type?: string;
  features?: string[];
  record?: {
    time?: number;
    name?: string;
  };
  preview?: Array<[number, number]>;
}

export interface RaceHistoryEntry {
  id: string;
  raceId?: string;
  routeId?: string;
  routeName: string;
  position: number;
  totalPlayers: number;
  time?: number;
  dnf?: boolean;
  prizeWon: number;
  prizePool: number;
  repGained: number;
  totalRep: number;
  betAmount: number;
  reason?: string;
  finishedAt: number;
  personalBest?: boolean;
  globalRecord?: boolean;
  winnerName?: string;
}

export interface PersonalRouteRecord {
  routeId: string;
  routeName: string;
  time: number;
  position: number;
  prizeWon: number;
  repGained: number;
  finishedAt: number;
}

export interface PlayerStats {
  totalRaces: number;
  wins: number;
  topThree: number;
  winRate: number;
  avgFinishPosition: number;
  bestTime?: number;
  bestTimeRoute?: string;
  totalPrizeMoney: number;
  currentStreak: number;
  bestStreak: number;
  repHistory: number[];
  history: RaceHistoryEntry[];
  personalRecords: PersonalRouteRecord[];
  rank?: number;
}

export interface NetworkData {
  onlineCount: number;
  lobbyCount: number;
  activeRaceCount: number;
  nearbyPoliceCount: number;
  radio?: {
    enabled: boolean;
    available: boolean;
    voiceResource: string;
    channel: number;
    joined: boolean;
    crewCount: number;
    inLobby: boolean;
    status: string;
    autoJoinOnRaceStart: boolean;
    currentVoiceChannel?: number;
    previousChannel?: number | null;
    localState?: Record<string, unknown>;
  };
  racers: Array<{
    id: string;
    name: string;
    status: 'racing' | 'lobby' | 'idle';
    rep: number;
    inVoice?: boolean;
  }>;
}

export interface TabletSettings {
  soundEffects: boolean;
  notifications: boolean;
  policeAlerts: boolean;
  raceInvites: boolean;
  showHud: boolean;
  music: boolean;
  volume: number;
  hudOpacity: number;
  theme: 'dark' | 'light';
}

const sanitizeArray = <T,>(value: unknown): T[] => Array.isArray(value) ? value as T[] : [];

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

const defaultRaceRadio: NonNullable<NetworkData['radio']> = {
  enabled: true,
  available: false,
  voiceResource: 'pma-voice',
  channel: 0,
  joined: false,
  crewCount: 0,
  inLobby: false,
  status: 'idle',
  autoJoinOnRaceStart: true
};

const defaultNetwork: NetworkData = {
  onlineCount: 0,
  lobbyCount: 0,
  activeRaceCount: 0,
  nearbyPoliceCount: 0,
  radio: defaultRaceRadio,
  racers: []
};

const defaultSettings: TabletSettings = {
  soundEffects: true,
  notifications: true,
  policeAlerts: true,
  raceInvites: true,
  showHud: true,
  music: false,
  volume: 80,
  hudOpacity: 100,
  theme: 'dark'
};

export default function App() {
  const [screen, setScreen] = useState<Screen>(isDebug ? 'tablet' : 'none');
  const [raceState, setRaceState] = useState<RaceState>({
    currentCheckpoint: 0,
    totalCheckpoints: 10,
    speed: 0,
    position: 1,
    totalPlayers: 4,
    players: [],
    policeWarning: false
  });
  const [countdown, setCountdown] = useState(5);
  const [routeName, setRouteName] = useState('Downtown Drift');
  const [results, setResults] = useState<ResultsData | null>(null);
  const [lobbyData, setLobbyData] = useState<any>(null);
  const [availableLobbies, setAvailableLobbies] = useState<LobbySummary[]>([]);
  const [routes, setRoutes] = useState<RouteSummary[]>([]);
  const [routeRecords, setRouteRecords] = useState<Record<string, RouteSummary['record']>>({});
  const [leaderboardData, setLeaderboardData] = useState<any[]>([]);
  const [playerStats, setPlayerStats] = useState<PlayerStats>(defaultStats);
  const [networkData, setNetworkData] = useState<NetworkData>(defaultNetwork);
  const [settings, setSettings] = useState<TabletSettings>(defaultSettings);
  const [playerRep, setPlayerRep] = useState(0);
  const [serverId, setServerId] = useState<number | null>(null);
  const policeWarningTimer = useRef<number | null>(null);
  const hudOpacity = Math.max(30, Math.min(100, Number(settings.hudOpacity) || 100));

  const handleClose = useCallback(() => {
    setScreen('none');
    fetchNui('close', {}, { success: true });
  }, []);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && screen !== 'none') {
        handleClose();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [handleClose, screen]);

  useEffect(() => {
    if (screen === 'tablet') {
      fetchNui('getDashboardData', {}, { success: true });
    }
  }, [screen]);

  useNuiEvent('open', (data: any) => {
    if (data?.lobby !== undefined) setLobbyData(data.lobby || null);
    if (data?.rep !== undefined) setPlayerRep(Math.max(0, Number(data.rep) || 0));
    if (data?.serverId !== undefined) setServerId(Number(data.serverId) || null);
    if (data?.lobbies !== undefined) setAvailableLobbies(sanitizeArray<LobbySummary>(data.lobbies));
    if (data?.routes !== undefined) {
      setRoutes(sanitizeArray<RouteSummary>(data.routes).map(route => ({
        ...route,
        record: routeRecords[route.id] || route.record
      })));
    }
    if (data?.leaderboard !== undefined) setLeaderboardData(sanitizeArray(data.leaderboard));
    if (data?.stats !== undefined) setPlayerStats({ ...defaultStats, ...data.stats });
    if (data?.network !== undefined) {
      setNetworkData({
        ...defaultNetwork,
        ...data.network,
        radio: {
          ...defaultRaceRadio,
          ...(data.network?.radio || {})
        },
        racers: sanitizeArray(data.network?.racers)
      });
    }
    if (data?.settings !== undefined) setSettings({ ...defaultSettings, ...data.settings });
    setScreen('tablet');
  });

  useNuiEvent('close', () => setScreen('none'));

  useNuiEvent('setVisible', (data: any) => {
    if (data?.visible === false) setScreen('none');
  });

  useNuiEvent('showRaceHUD', (data: any) => {
    const players = sanitizeArray<PlayerData>(data?.players);
    const totalCheckpoints = Math.max(1, Number(data?.totalCheckpoints) || 1);
    setRaceState({
      currentCheckpoint: 0,
      totalCheckpoints,
      speed: 0,
      position: 1,
      totalPlayers: Math.max(1, players.length),
      players,
      policeWarning: false
    });
    setScreen('racehud');
  });

  useNuiEvent('hideRaceHUD', () => setScreen('none'));

  useNuiEvent('showCountdown', (data: any) => {
    setCountdown(Math.max(1, Number(data?.countdown) || 5));
    setRouteName(data?.routeName || 'Race');
    setScreen('countdown');
  });

  useNuiEvent('updateCheckpoint', (data: any) => {
    setRaceState(prev => {
      const total = Math.max(1, Number(data?.total) || prev.totalCheckpoints || 1);
      return {
        ...prev,
        currentCheckpoint: Math.min(total, Math.max(0, Number(data?.current) || 0)),
        totalCheckpoints: total
      };
    });
  });

  useNuiEvent('updateSpeed', (data: any) => {
    setRaceState(prev => ({ ...prev, speed: Math.max(0, Number(data?.speed) || 0) }));
  });

  useNuiEvent('playerFinished', (data: any) => {
    if (!data?.name) return;
    setRaceState(prev => ({
      ...prev,
      players: prev.players.map(p =>
        p.name === data.name
          ? { ...p, position: Number(data.position) || p.position, finished: true }
          : p
      )
    }));
  });

  useNuiEvent('showResults', (data: ResultsData) => {
    setResults({
      results: sanitizeArray<ResultItem>(data?.results),
      prizePool: Number(data?.prizePool) || 0,
      reason: data?.reason
    });
    setScreen('results');
  });

  useNuiEvent('policeWarning', () => {
    if (settings.policeAlerts === false) return;
    if (policeWarningTimer.current) window.clearTimeout(policeWarningTimer.current);
    setRaceState(prev => ({ ...prev, policeWarning: true }));
    policeWarningTimer.current = window.setTimeout(() => {
      setRaceState(prev => ({ ...prev, policeWarning: false }));
      policeWarningTimer.current = null;
    }, 3000);
  });

  useNuiEvent('lobbyUpdate', (data: any) => {
    setLobbyData(data || null);
    if (screen === 'none') setScreen('tablet');
  });

  useNuiEvent('leftLobby', () => {
    setLobbyData(null);
    if (screen === 'tablet') fetchNui('getDashboardData', {}, { success: true });
  });

  useNuiEvent('receiveLeaderboard', (data: any[]) => {
    setLeaderboardData(sanitizeArray(data));
    if (screen === 'none') setScreen('tablet');
  });

  useNuiEvent('receivePlayerData', (data: any) => {
    setPlayerRep(Math.max(0, Number(data?.rep) || 0));
    if (data?.serverId !== undefined) setServerId(Number(data.serverId) || null);
  });

  useNuiEvent('receiveLobbies', (data: LobbySummary[]) => {
    setAvailableLobbies(sanitizeArray<LobbySummary>(data));
  });

  useNuiEvent('receiveRoutes', (data: RouteSummary[]) => {
    setRoutes(sanitizeArray<RouteSummary>(data).map(route => ({
      ...route,
      record: routeRecords[route.id] || route.record
    })));
  });

  useNuiEvent('receiveRouteRecords', (records: Record<string, RouteSummary['record']>) => {
    if (!records || typeof records !== 'object') return;
    setRouteRecords(records);
    setRoutes(prev => prev.map(route => ({
      ...route,
      record: records[route.id] || route.record
    })));
  });

  useNuiEvent('receivePlayerStats', (data: PlayerStats) => {
    setPlayerStats({ ...defaultStats, ...(data || {}) });
  });

  useNuiEvent('receiveNetwork', (data: NetworkData) => {
    setNetworkData({
      ...defaultNetwork,
      ...(data || {}),
      radio: {
        ...defaultRaceRadio,
        ...(data?.radio || {})
      },
      racers: sanitizeArray(data?.racers)
    });
  });

  useNuiEvent('receiveRaceRadio', (data: NonNullable<NetworkData['radio']>) => {
    setNetworkData(prev => ({
      ...prev,
      radio: {
        ...defaultRaceRadio,
        ...(prev.radio || {}),
        ...(data || {})
      }
    }));
  });

  useNuiEvent('raceRadioUpdate', (data: any) => {
    setNetworkData(prev => ({
      ...prev,
      radio: {
        ...defaultRaceRadio,
        ...(prev.radio || {}),
        available: data?.available ?? prev.radio?.available ?? false,
        joined: data?.joined ?? prev.radio?.joined ?? false,
        channel: data?.channel ?? prev.radio?.channel ?? 0,
        currentVoiceChannel: data?.currentVoiceChannel,
        previousChannel: data?.previousChannel,
        localState: data || {}
      }
    }));
  });

  useNuiEvent('receiveSettings', (data: TabletSettings) => {
    setSettings({ ...defaultSettings, ...(data || {}) });
  });

  useEffect(() => {
    if (!isDebug) return;

    setRoutes([
      { id: 'downtown_drift', name: 'Downtown Drift', description: 'Navigate the city streets', minRep: 0, entryFee: 500, checkpointCount: 15, difficulty: 'Easy', type: 'urban', record: { time: 134876, name: 'SpeedDemon' } },
      { id: 'harbor_run', name: 'Harbor Run', description: 'Industrial speed run', minRep: 50, entryFee: 1500, checkpointCount: 18, difficulty: 'Medium', type: 'industrial' },
      { id: 'vinewood_escape', name: 'Vinewood Escape', description: 'Elite hills and curves', minRep: 150, entryFee: 5000, checkpointCount: 22, difficulty: 'Hard', type: 'hills' }
    ]);
    setAvailableLobbies([
      { id: 'sample_lobby', routeName: 'Downtown Drift', hostName: 'SpeedDemon', playerCount: 2, maxPlayers: 8, betAmount: 500, prizePool: 1000, minRep: 0 }
    ]);
    setNetworkData({
      onlineCount: 8,
      lobbyCount: 1,
      activeRaceCount: 1,
      nearbyPoliceCount: 0,
      radio: {
        enabled: true,
        available: true,
        voiceResource: 'pma-voice',
        channel: 742,
        joined: false,
        crewCount: 1,
        inLobby: true,
        status: 'waiting',
        autoJoinOnRaceStart: true
      },
      racers: [
        { id: '1', name: 'SpeedDemon', status: 'lobby', rep: 542, inVoice: true },
        { id: '2', name: 'NightRider', status: 'racing', rep: 423, inVoice: false }
      ]
    });
    setPlayerStats({
      ...defaultStats,
      totalRaces: 12,
      wins: 4,
      topThree: 8,
      winRate: 33.3,
      avgFinishPosition: 2.4,
      bestTime: 134876,
      bestTimeRoute: 'Downtown Drift',
      totalPrizeMoney: 42000,
      currentStreak: 2,
      bestStreak: 3,
      repHistory: [10, 35, 60, 90, 120, 150],
      personalRecords: [
        { routeId: 'downtown_drift', routeName: 'Downtown Drift', time: 134876, position: 1, prizeWon: 5000, repGained: 25, finishedAt: 1760000000 },
        { routeId: 'harbor_run', routeName: 'Harbor Run', time: 188432, position: 2, prizeWon: 0, repGained: 15, finishedAt: 1760003600 }
      ],
      history: [
        { id: 'sample-1', routeId: 'downtown_drift', routeName: 'Downtown Drift', position: 1, totalPlayers: 4, time: 134876, prizeWon: 5000, prizePool: 5000, repGained: 25, totalRep: 150, betAmount: 500, reason: 'complete', finishedAt: 1760000000, personalBest: true, globalRecord: true, winnerName: 'SpeedDemon' },
        { id: 'sample-2', routeId: 'harbor_run', routeName: 'Harbor Run', position: 2, totalPlayers: 5, time: 188432, prizeWon: 0, prizePool: 7500, repGained: 15, totalRep: 125, betAmount: 1500, reason: 'complete', finishedAt: 1760003600, personalBest: true, winnerName: 'NightRider' },
        { id: 'sample-3', routeId: 'vinewood_escape', routeName: 'Vinewood Escape', position: 4, totalPlayers: 4, dnf: true, prizeWon: 0, prizePool: 20000, repGained: 5, totalRep: 110, betAmount: 5000, reason: 'timeout', finishedAt: 1760007200, winnerName: 'DriftKing' }
      ]
    });
    setRaceState({
      currentCheckpoint: 3,
      totalCheckpoints: 10,
      speed: 145,
      position: 2,
      totalPlayers: 4,
      players: [
        { name: 'SpeedDemon', position: 1, finished: false },
        { name: 'NightRider', position: 2, finished: false },
        { name: 'FastLane', position: 3, finished: false },
        { name: 'TurboKing', position: 4, finished: false }
      ],
      policeWarning: false
    });
    setLeaderboardData([
      { rank: 1, name: 'SpeedDemon', rep: 542, wins: 45, races: 89, streak: 5 },
      { rank: 2, name: 'NightRider', rep: 423, wins: 38, races: 76, streak: 3 },
      { rank: 3, name: 'FastLane', rep: 387, wins: 32, races: 68, streak: 0 }
    ]);
    setResults({
      results: [
        { name: 'SpeedDemon', position: 1, repGained: 25, prizeWon: 5000, time: 125340 },
        { name: 'NightRider', position: 2, repGained: 15, time: 127890 },
        { name: 'FastLane', position: 3, repGained: 10, time: 130450 }
      ],
      prizePool: 5000
    });
  }, []);

  return (
    <div className="w-screen h-screen overflow-hidden pointer-events-none">
      <AnimatePresence mode="wait">
        {screen === 'tablet' && (
          <TabletDashboard
            key="tablet"
            playerRep={playerRep}
            lobbyData={lobbyData}
            availableLobbies={availableLobbies}
            routes={routes}
            leaderboardData={leaderboardData}
            playerStats={playerStats}
            networkData={networkData}
            settings={settings}
            serverId={serverId}
            onClose={handleClose}
          />
        )}
        {screen === 'countdown' && <Countdown key="countdown" countdown={countdown} routeName={routeName} />}
        {screen === 'racehud' && settings.showHud !== false && <RaceHUD key="racehud" {...raceState} hudOpacity={hudOpacity} />}
        {screen === 'results' && <Results key="results" results={results?.results || []} prizePool={results?.prizePool || 0} onClose={handleClose} />}
      </AnimatePresence>
    </div>
  );
}
