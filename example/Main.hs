{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-unused-imports #-}

module Main where

import Control.Monad (forever)
import Data.ByteString.Lazy qualified as BL
import Data.String.Conversions (cs)
import Data.String.Interpolate (i)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Lazy qualified as L
import Data.Text.Lazy.Encoding qualified as L
import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.State.Static.Local
import Example.Contacts qualified as Contacts
import Example.Effects.Debug
import Example.Effects.Users as Users
import GHC.Generics (Generic)
import Network.HTTP.Types (Method, QueryItem, methodPost, status200, status404)
import Network.Wai ()
import Network.Wai.Handler.Warp (run)
import Network.Wai.Handler.WebSockets (websocketsOr)
import Network.Wai.Middleware.Static (addBase, staticPolicy)
import Web.Hyperbole
import Web.UI


main :: IO ()
main = do
  putStrLn "Starting Examples on :3001"
  users <- initUsers
  run 3001
    $ staticPolicy (addBase "dist")
    $ app users


data AppRoute
  = Main
  | Hello Hello
  | Contacts
  | Echo
  deriving (Show, Generic, Eq, Route)


data Hello
  = Greet Text
  deriving (Show, Generic, Eq, Route)


app :: UserStore -> Application
app users = waiApplication document (runUsersIO users . runPageWai . runDebugIO . router)
 where
  router :: (Page :> es, Users :> es, Debug :> es) => AppRoute -> Eff es ()
  router (Hello h) = hello h
  router Echo = do
    f <- formData
    view $ col id $ do
      el id "ECHO:"
      text $ cs $ show f
  router Contacts = Contacts.page
  router Main = view $ do
    col (gap 10 . pad 10) $ do
      el (bold . fontSize 32) "Examples"
      link (routeUrl (Hello (Greet "World"))) id "Hello World"
      link (routeUrl Contacts) id "Contacts"

  hello (Greet s) = view $ el (pad 10) "GREET" >> text s


document :: BL.ByteString -> BL.ByteString
document cnt =
  [i|<html>
    <head>
      <title>Hyperbole Examples</title>
      <script type="text/javascript" src="/main.js"></script>
      <style type type="text/css">#{cssResetEmbed}</style>
    </head>
    <body>#{cnt}</body>
  </html>|]

-- document :: BL.ByteString -> BL.ByteString
-- document cnt =
--   [i|<html>
--     <head>
--       <title>Hyperbole Examples</title>
--       <script type="text/javascript">#{scriptEmbed}</script>
--       <style type type="text/css">#{cssResetEmbed}</style>
--     </head>
--     <body>#{cnt}</body>
--   </html>|]
