module Lib
    ( someFunc
    ) where

import Data.Monoid ((<>))
import Data.Word (Word8)
-- import qualified MyNetwork.AMQP as AMQP      <-- a copy of the AMQP code with tracing added
import qualified Network.AMQP as AMQP
import qualified Data.ByteString.Lazy as LBS


someFunc :: IO ()
someFunc = do
    putText "Starting"

    conn <- AMQP.openConnection''
                AMQP.defaultConnectionOpts
                    { AMQP.coServers        = [("queue.service", 5672)]
                    , AMQP.coVHost          = "/"
                    , AMQP.coAuth           = [AMQP.plain "indicee" "indicee"]
                    , AMQP.coHeartbeatDelay =  Just 10
                    }
    putText "RabbitMP Connection established"
    chan <- AMQP.openChannel conn
    putText "Channel opened"

    let msgContent =
            AMQP.newMsg { AMQP.msgBody =
                                -- LBS.replicate (1024 * 1) (fromIntegral 55)      --  <-- This is Ok
                                LBS.replicate (1024 * 1024 * 5) (55 :: Word8)      --  <-- This causes CPU to get stuck at 100%
                        , AMQP.msgDeliveryMode = Just AMQP.Persistent
                        }

    let routingKey = "Test.Test"

    putText "Starting publish"
    res <- AMQP.publishMsg chan "workResultExchange" routingKey msgContent
    putText $ "Finished publish:  result = " <> show res

    putText "<press Enter to finish>"
    _ <- getLine -- wait for keypress
    AMQP.closeConnection conn
    putText "connection closed"
    putText "DONE"


putText = putStrLn
