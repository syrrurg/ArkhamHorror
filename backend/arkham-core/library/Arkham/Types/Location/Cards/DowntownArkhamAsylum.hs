{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Location.Cards.DowntownArkhamAsylum
  ( DowntownArkhamAsylum(..)
  , downtownArkhamAsylum
  )
where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Helpers
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype DowntownArkhamAsylum = DowntownArkhamAsylum Attrs
  deriving newtype (Show, ToJSON, FromJSON)

downtownArkhamAsylum :: DowntownArkhamAsylum
downtownArkhamAsylum = DowntownArkhamAsylum $ base { locationVictory = Just 1 }
 where
  base = baseAttrs
    "01131"
    (LocationName "Downtown" $ Just "Arkham Asylum")
    EncounterSet.TheMidnightMasks
    4
    (PerPlayer 2)
    Triangle
    [Moon, T]
    [Arkham]

instance HasModifiersFor env DowntownArkhamAsylum where
  getModifiersFor = noModifiersFor

ability :: Attrs -> Ability
ability attrs =
  (mkAbility (toSource attrs) 1 (ActionAbility Nothing $ ActionCost 1))
    { abilityLimit = PerGame
    }

instance ActionRunner env => HasActions env DowntownArkhamAsylum where
  getActions iid NonFast (DowntownArkhamAsylum attrs@Attrs {..})
    | locationRevealed = withBaseActions iid NonFast attrs $ do
      unused <- getIsUnused iid (ability attrs)
      canAffordActions <- getCanAffordCost
        iid
        (toSource attrs)
        Nothing
        (ActionCost 1)
      pure
        [ ActivateCardAbilityAction iid (ability attrs)
        | unused && iid `elem` locationInvestigators && canAffordActions
        ]
  getActions iid window (DowntownArkhamAsylum attrs) =
    getActions iid window attrs

instance (LocationRunner env) => RunMessage env DowntownArkhamAsylum where
  runMessage msg l@(DowntownArkhamAsylum attrs) = case msg of
    UseCardAbility iid source _ 1 | isSource attrs source ->
      l <$ unshiftMessage (HealHorror (InvestigatorTarget iid) 3)
    _ -> DowntownArkhamAsylum <$> runMessage msg attrs
