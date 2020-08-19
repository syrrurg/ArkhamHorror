module Arkham.Types.Event.Cards.Evidence where

import Arkham.Types.Classes
import Arkham.Types.GameRunner
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Query
import ClassyPrelude

evidence
  :: (MonadReader env m, GameRunner env, MonadIO m) => InvestigatorId -> m ()
evidence iid = do
  currentLocationId <- asks (getId @LocationId iid)
  locationClueCount <- unClueCount <$> asks (getCount currentLocationId)
  if locationClueCount > 0
    then unshiftMessage (DiscoverCluesAtLocation iid currentLocationId 1)
    else pure ()
