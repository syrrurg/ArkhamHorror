{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Treachery.Cards.Atychiphobia
  ( atychiphobia
  , Atychiphobia(..)
  )
where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Helpers
import Arkham.Types.Treachery.Runner

newtype Atychiphobia = Atychiphobia Attrs
  deriving newtype (Show, ToJSON, FromJSON)

atychiphobia :: TreacheryId -> Maybe InvestigatorId -> Atychiphobia
atychiphobia uuid iid = Atychiphobia $ weaknessAttrs uuid iid "60504"

instance HasModifiersFor env Atychiphobia where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Atychiphobia where
  getActions iid NonFast (Atychiphobia a@Attrs {..}) =
    withTreacheryInvestigator a $ \tormented -> do
      canActivate <- getCanAffordCost iid (toSource a) Nothing (ActionCost 2)
      investigatorLocationId <- getId @LocationId iid
      treacheryLocation <- getId tormented
      pure
        [ ActivateCardAbilityAction
            iid
            (mkAbility (toSource a) 1 (ActionAbility Nothing $ ActionCost 2))
        | treacheryLocation == investigatorLocationId && canActivate
        ]
  getActions _ _ _ = pure []

instance (TreacheryRunner env) => RunMessage env Atychiphobia where
  runMessage msg t@(Atychiphobia attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ unshiftMessage (AttachTreachery treacheryId $ InvestigatorTarget iid)
    FailedSkillTest iid _ _ _ _ | treacheryOnInvestigator iid attrs ->
      t <$ unshiftMessage
        (InvestigatorAssignDamage iid (TreacherySource treacheryId) 0 1)
    UseCardAbility _ (TreacherySource tid) _ 1 | tid == treacheryId ->
      t <$ unshiftMessage (Discard (TreacheryTarget treacheryId))
    _ -> Atychiphobia <$> runMessage msg attrs
