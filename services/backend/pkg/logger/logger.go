package logger

import (
	"os"
	"strings"
	"sync"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var (
	log  *zap.Logger
	once sync.Once
)

func Init(env string) {
	once.Do(func() {
		isProd := strings.ToLower(env) == "production"

		var level zapcore.Level
		var encoder zapcore.Encoder

		if isProd {
			level = zapcore.InfoLevel
			encoderConfig := zap.NewProductionEncoderConfig()
			encoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
			encoder = zapcore.NewJSONEncoder(encoderConfig)
		} else {
			level = zapcore.DebugLevel
			encoderConfig := zapcore.EncoderConfig{
				MessageKey:   "msg",
				LevelKey:     "level",
				TimeKey:      "time",
				EncodeLevel:  zapcore.CapitalColorLevelEncoder,
				EncodeTime:   zapcore.TimeEncoderOfLayout("15:04:05"),
				EncodeCaller: zapcore.ShortCallerEncoder,
			}
			encoder = zapcore.NewConsoleEncoder(encoderConfig)
		}

		core := zapcore.NewCore(encoder, zapcore.AddSync(os.Stdout), level)
		log = zap.New(core, zap.AddCaller(), zap.AddCallerSkip(1))
	})
}

func Get() *zap.Logger {
	if log == nil {
		Init("development")
	}
	return log
}

// Standalone Functional API

func Info(msg string, fields ...zap.Field) {
	Get().Info(msg, fields...)
}

func Debug(msg string, fields ...zap.Field) {
	Get().Debug(msg, fields...)
}

func Warn(msg string, fields ...zap.Field) {
	Get().Warn(msg, fields...)
}

func Error(msg string, fields ...zap.Field) {
	Get().Error(msg, fields...)
}

func Fatal(msg string, fields ...zap.Field) {
	Get().Fatal(msg, fields...)
}
