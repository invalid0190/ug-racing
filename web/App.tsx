import { useState, useEffect, useCallback, useRef } from 'react';
import { AnimatePresence } from 'framer-motion';
import { isDebug, useNuiEvent, fetchNui } from './hooks/useNui';
import RaceHUD from './components/RaceHUD';
import Countdown from './components/Countdown';
import Results from './components/Results';
import Lobby from './components/Lobby';
import Leaderboard from './components/Leaderboard';

type Screen = 'none' | 'lobby' | 'leaderboard' | 'racehud' | 'countdown' | 'results';

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
  time: number;
}

interface ResultsData {
  results: ResultItem[];
  prizePool: number;
  reason?: string;
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

const sanitizeArray = <T,>(value: unknown): T[] => Array.isArray(value) ? value as T[] : [];

export default function App() {
  const [screen, setScreen] = useState<Screen>(isDebug ? 'lobby' : 'none');
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
  const [leaderboardData, setLeaderboardData] = useState<any[]>([]);
  const [playerRep, setPlayerRep] = useState(0);
  const [serverId, setServerId] = useState<number | null>(null);
  const policeWarningTimer = useRef<number | null>(null);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && screen !== 'none') {
        setScreen('none');
        fetchNui('close', {}, { success: true });
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [screen]);

  useNuiEvent('open', (data: any) => {
    if (data?.lobby) {
      setLobbyData(data.lobby);
      setScreen('lobby');
    } else {
      setScreen('lobby');
    }
  });

  useNuiEvent('close', () => setScreen('none'));

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
    const total = Math.max(1, Number(data?.total) || raceState.totalCheckpoints || 1);
    setRaceState(prev => ({
      ...prev,
      currentCheckpoint: Math.min(total, Math.max(0, Number(data?.current) || 0)),
      totalCheckpoints: total
    }));
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
          ? { ...p, position: data.position, finished: true }
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
    if (policeWarningTimer.current) window.clearTimeout(policeWarningTimer.current);
    setRaceState(prev => ({ ...prev, policeWarning: true }));
    policeWarningTimer.current = window.setTimeout(() => {
      setRaceState(prev => ({ ...prev, policeWarning: false }));
      policeWarningTimer.current = null;
    }, 3000);
  });

  useNuiEvent('lobbyUpdate', (data: any) => {
    setLobbyData(data || null);
    if (screen === 'none') setScreen('lobby');
  });

  useNuiEvent('leftLobby', () => {
    setLobbyData(null);
    if (screen === 'lobby') setScreen('none');
  });

  useNuiEvent('receiveLeaderboard', (data: any[]) => {
    setLeaderboardData(sanitizeArray(data));
    setScreen('leaderboard');
  });

  useNuiEvent('receivePlayerData', (data: any) => {
    setPlayerRep(Math.max(0, Number(data?.rep) || 0));
    if (typeof data?.serverId === 'number') setServerId(data.serverId);
  });

  useNuiEvent('receiveLobbies', (data: LobbySummary[]) => {
    setAvailableLobbies(sanitizeArray<LobbySummary>(data));
  });

  const handleClose = useCallback(() => {
    setScreen('none');
    fetchNui('close', {}, { success: true });
  }, []);

  useEffect(() => {
    if (isDebug) {
      setRaceState({
        currentCheckpoint: 3, totalCheckpoints: 10, speed: 145, position: 2,
        totalPlayers: 4, players: [
          { name: 'SpeedDemon', position: 1, finished: false },
          { name: 'NightRider', position: 2, finished: false },
          { name: 'FastLane', position: 3, finished: false },
          { name: 'TurboKing', position: 4, finished: false }
        ], policeWarning: false
      });
      setLeaderboardData([
        { name: 'SpeedDemon', rep: 542 }, { name: 'NightRider', rep: 423 },
        { name: 'FastLane', rep: 387 }, { name: 'TurboKing', rep: 312 }
      ]);
      setResults({
        results: [
          { name: 'SpeedDemon', position: 1, repGained: 25, prizeWon: 5000, time: 125340 },
          { name: 'NightRider', position: 2, repGained: 15, time: 127890 },
          { name: 'FastLane', position: 3, repGained: 10, time: 130450 }
        ], prizePool: 5000
      });
    }
  }, []);

  return (
    <div className="w-screen h-screen overflow-hidden pointer-events-none">
      <AnimatePresence mode="wait">
        {screen === 'lobby' && <Lobby key="lobby" lobbyData={lobbyData} availableLobbies={availableLobbies} playerRep={playerRep} serverId={serverId} onClose={handleClose} />}
        {screen === 'leaderboard' && <Leaderboard key="leaderboard" data={leaderboardData} playerRep={playerRep} onClose={() => setScreen('lobby')} />}
        {screen === 'countdown' && <Countdown key="countdown" countdown={countdown} routeName={routeName} />}
        {screen === 'racehud' && <RaceHUD key="racehud" {...raceState} />}
        {screen === 'results' && <Results key="results" results={results?.results || []} prizePool={results?.prizePool || 0} onClose={handleClose} />}
      </AnimatePresence>
    </div>
  );
}
