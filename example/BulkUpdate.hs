module BulkUpdate where

import Control.Monad (forM_)
import Control.Monad.IO.Class (liftIO)
import Data.Text (pack)
import Example.Colors
import Example.Effects.Users (User (..), UserStore)
import Example.Effects.Users qualified as Users
import Web.Htmx
import Web.Hyperbole (view)
import Web.Hyperbole.Htmx
import Web.Scotty hiding (text)
import Web.UI

route :: UserStore -> ScottyM ()
route st = do
  get "/contacts/" $ do
    us <- Users.all st
    view $ viewMain us

  -- scotty doesn't support multiple ids :(
  post "/contacts/activate" $ do
    ids <- param "ids" :: ActionM [Int]
    liftIO $ print ids
    forM_ ids $ \uid ->
      Users.modify st uid $ \u -> u{isActive = True}
    us <- Users.all st
    view $ viewUsers us

  post "/contacts/deactivate" $ do
    ids <- param "ids" :: ActionM [Int]
    liftIO $ print ids
    forM_ ids $ \uid ->
      Users.modify st uid $ \u -> u{isActive = False}
    us <- Users.all st
    view $ viewUsers us

viewMain :: [User] -> View ()
viewMain users = do
  row (hxTarget (Query (Id "table")) . hxSwap OuterHTML . hxInclude (Id "form")) $ do
    col (pad 20 . width 500) $ do
      button (hxPost ("contacts" // "activate")) "Activate"
      button (hxPost ("contacts" // "deactivate")) "Deactivate"

    form (grow . pad 10 . att "id" "form") $ do
      viewUsers users

viewUsers :: [User] -> View ()
viewUsers users = do
  table (border 1 . att "id" "table") users $ do
    tcol (cell . width 20) none $ \u -> do
      input (att "type" "checkbox" . name "ids" . value (pack $ show u.id))

    tcol cell (hd "First Name") $ \u -> do
      el (if u.isActive then bold else id) $ text u.firstName

    tcol cell (hd "Last Name") $ \u -> do
      text u.lastName

    tcol cell (hd "Email") $ \u -> do
      text u.email
 where
  cell = pad 4 . border 1 . borderColor GrayLight
  hd = el bold

--
