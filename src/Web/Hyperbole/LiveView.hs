{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FunctionalDependencies #-}

module Web.Hyperbole.LiveView where

import Data.Text
import Text.Read
import Web.UI


-- | Associate a live id with a set of actions
class (Param id, Param action) => LiveView id action | id -> action


liveView :: forall id action ctx. (LiveView id action) => id -> View id () -> View ctx ()
liveView vid vw = do
  el (att "id" (toParam vid) . flexCol)
    $ addContext vid vw


liveForm :: (LiveView id action) => action -> Mod -> View id () -> View id ()
liveForm a f cd = do
  c <- context
  tag "form" (onSubmit a . dataTarget c . f . flexCol) cd


submitButton :: Mod -> View c () -> View c ()
submitButton f = tag "button" (att "type" "submit" . f)


liveButton :: (LiveView id action) => action -> Mod -> View id () -> View id ()
liveButton a f cd = do
  c <- context
  tag "button" (att "data-on-click" (toParam a) . dataTarget c . f) cd


onRequest :: View id () -> View id () -> View id ()
onRequest a b = do
  el (parent "request" flexCol . display None) a
  el (parent "request" (display None) . flexCol) b


-- | Internal
dataTarget :: (Param a) => a -> Mod
dataTarget = att "data-target" . toParam


onSubmit :: (Param a) => a -> Mod
onSubmit = att "data-on-submit" . toParam


-- | Change the target of any code running inside, allowing actions to target other live views on the page
target :: (LiveView id action) => id -> View id () -> View a ()
target vid vw =
  addContext vid vw


liveSelect
  :: (LiveView id action)
  => (opt -> action)
  -> opt
  -> View (Option opt id action) ()
  -> View id ()
liveSelect toAction sel options = do
  c <- context
  tag "select" (att "data-on-change" "" . dataTarget c) $ do
    addContext (Option toAction sel) options


option
  :: (LiveView id action, Eq opt)
  => opt
  -> Mod
  -> View (Option opt id action) ()
  -> View (Option opt id action) ()
option opt f cnt = do
  os <- context
  tag "option" (att "value" (toParam (os.toAction opt)) . isSelected (opt == os.selected) . f) cnt


isSelected :: Bool -> Mod
isSelected b = if b then att "selected" "true" else id


data Option opt id action = Option
  { toAction :: opt -> action
  , selected :: opt
  }


class Param a where
  -- not as flexible as FromHttpApiData, but derivable
  parseParam :: Text -> Maybe a
  default parseParam :: (Read a) => Text -> Maybe a
  parseParam = readMaybe . unpack


  toParam :: a -> Text
  default toParam :: (Show a) => a -> Text
  toParam = pack . show


instance Param Integer
instance Param Float
instance Param Int
instance Param ()


instance Param Text where
  parseParam = pure
  toParam = id
