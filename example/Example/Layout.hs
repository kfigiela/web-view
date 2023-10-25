module Example.Layout where

import Effectful
import Example.Colors
import Web.Hyperbole
import Web.UI


-- need to be able to set bg color of page, sure
page :: (Page :> es) => Eff es ()
page = do
  view $ layout (bg GrayLight) $ col (grow . big flexRow) $ do
    el (gap 10 . pad 20 . bg Primary . color White . small topbar . big sidebar) $ do
      el_ "SIDEBAR"
      el_ "One"
      el_ "Two"
      el_ "Three"

    col (pad 20 . grow . bg White) $ el_ "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?"
 where
  sidebar = width 400 . flexCol
  topbar = height 100 . flexRow
  big = media (MinWidth 800)
  small = media (MaxWidth 800)