import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Zap } from 'lucide-react';

interface CountdownProps {
  countdown: number;
  routeName: string;
}

const speedLines = Array.from({ length: 16 }, (_, i) => ({
  top: `${5 + i * 6}%`,
  width: `${50 + (i % 5) * 8}%`,
  delay: `${i * 0.15}s`,
  duration: `${1.5 + (i % 4) * 0.35}s`,
  reverse: i % 2 === 0
}));

export default function Countdown({ countdown: initialCount, routeName }: CountdownProps) {
  const [count, setCount] = useState(initialCount);
  const [showGo, setShowGo] = useState(false);

  useEffect(() => {
    setCount(Math.max(1, Number(initialCount) || 1));
    setShowGo(false);
  }, [initialCount]);

  useEffect(() => {
    if (count > 0) {
      const timer = setTimeout(() => setCount(count - 1), 1000);
      return () => clearTimeout(timer);
    } else if (count === 0 && !showGo) {
      setShowGo(true);
    }
  }, [count, showGo]);

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
              animationDelay: line.delay,
              animationDuration: line.duration
            }}
          />
        ))}
      </div>

      <div className="text-center relative z-10">
        {/* Route Name */}
        <motion.div
          initial={{ opacity: 0, y: -30 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-zinc-500 text-xl mb-6 tracking-[0.3em] uppercase font-semibold"
        >
          {routeName}
        </motion.div>

        {/* Countdown Number */}
        <AnimatePresence mode="wait">
          {!showGo ? (
            <motion.div
              key={count}
              initial={{ scale: 1.5, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.5, opacity: 0 }}
              transition={{ duration: 0.4, ease: 'easeOut' }}
              className="text-[12rem] font-bold text-white leading-none"
              style={{
                textShadow: `0 0 60px rgba(220, 38, 38, 0.8), 0 0 120px rgba(220, 38, 38, 0.5), 0 0 180px rgba(220, 38, 38, 0.3)`
              }}
            >
              {count}
            </motion.div>
          ) : (
            <motion.div
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              className="flex items-center justify-center gap-4"
            >
              <Zap size={80} className="text-green-400" strokeWidth={3} />
              <span
                className="text-[8rem] font-bold text-green-400 leading-none"
                style={{
                  textShadow: '0 0 60px rgba(34, 197, 94, 0.8), 0 0 120px rgba(34, 197, 94, 0.5)'
                }}
              >
                GO!
              </span>
              <Zap size={80} className="text-green-400" strokeWidth={3} />
            </motion.div>
          )}
        </AnimatePresence>

        {/* Get Ready text */}
        {!showGo && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-red-500 text-2xl mt-8 uppercase tracking-[0.2em] font-semibold"
          >
            Get Ready
          </motion.div>
        )}
      </div>
    </div>
  );
}
