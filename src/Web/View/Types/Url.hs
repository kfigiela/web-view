module Web.View.Types.Url where

import Control.Applicative ((<|>))
import Data.Maybe (fromMaybe)
import Data.String (IsString (..))
import Data.Text (Text, pack)
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8, encodeUtf8)
import Debug.Trace
import Effectful
import Effectful.State.Static.Local
import Network.HTTP.Types (Query, parseQuery, renderQuery)


type Segment = Text


pathUrl :: [Segment] -> Url
pathUrl p = Url "" "" p []


cleanSegment :: Segment -> Segment
cleanSegment = T.dropWhileEnd (== '/') . T.dropWhile (== '/')


pathSegments :: Text -> [Segment]
pathSegments p = filter (not . T.null) $ T.splitOn "/" $ T.dropWhile (== '/') p


-- Problem: if scheme and domain exist, it MUST be an absolute url
data Url = Url
  { scheme :: Text
  , domain :: Text
  , path :: [Segment]
  , query :: Query
  }
  deriving (Show, Eq)
instance IsString Url where
  fromString = url . pack


url :: Text -> Url
url t = runPureEff $ evalState (T.toLower t) $ do
  s <- scheme
  d <- domain s
  ps <- paths
  q <- query
  pure $ Url{scheme = s, domain = d, path = ps, query = q}
 where
  parse :: (State Text :> es) => (Char -> Bool) -> Eff es Text
  parse b = do
    inp <- get
    let match = T.takeWhile b inp
        rest = T.dropWhile b inp
    put rest
    pure match

  string :: (State Text :> es) => Text -> Eff es (Maybe Text)
  string pre = do
    inp <- get
    case T.stripPrefix pre inp of
      Nothing -> pure Nothing
      Just rest -> do
        traceM $ show ("Prefix" :: String, rest, pre, inp)
        put rest
        pure (Just pre)

  -- it's either scheme AND domain, or relative path
  scheme = do
    http <- string "http://"
    https <- string "https://"
    pure $ fromMaybe "" $ http <|> https

  domain "" = pure ""
  domain _ = parse (not . isDomainSep)

  pathText :: (State Text :> es) => Eff es Text
  pathText = parse (not . isQuerySep)

  paths :: (State Text :> es) => Eff es [Segment]
  paths = do
    p <- pathText
    pure $ pathSegments p

  query :: (State Text :> es) => Eff es Query
  query = do
    q <- parse (/= '\n')
    pure $ parseQuery $ encodeUtf8 q

  isDomainSep '/' = True
  isDomainSep _ = False

  isQuerySep '?' = True
  isQuerySep _ = False


renderUrl :: Url -> Text
renderUrl u = u.scheme <> u.domain <> paths u.path <> decodeUtf8 (renderQuery True u.query)
 where
  paths :: [Segment] -> Text
  paths ss = "/" <> T.intercalate "/" (map cleanSegment ss)
