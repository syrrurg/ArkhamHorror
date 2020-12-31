{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Asset.Cards.JazzMulligan
  ( jazzMulligan
  , JazzMulligan(..)
  )
where

import Arkham.Import

import Arkham.Types.Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Trait

newtype JazzMulligan = JazzMulligan Attrs
  deriving newtype (Show, ToJSON, FromJSON)

jazzMulligan :: AssetId -> JazzMulligan
jazzMulligan uuid = JazzMulligan $ (baseAttrs uuid "02060")
  { assetHealth = Just 2
  , assetSanity = Just 2
  , assetIsStory = True
  }

ability :: Attrs -> Ability
ability attrs =
  mkAbility (toSource attrs) 1 (ActionAbility Nothing $ ActionCost 1)

instance
  ( HasId LocationId env InvestigatorId
  , HasCostPayment env
  , HasModifiersFor env ()
  , HasSet Trait env Source
  )
  => HasActions env JazzMulligan where
  getActions iid NonFast (JazzMulligan attrs) = do
    lid <- getId iid
    canAfford <- getCanAffordCost
      iid
      (toSource attrs)
      (Just Parley)
      (ActionCost 1)
    case assetLocation attrs of
      Just location -> pure
        [ ActivateCardAbilityAction iid (ability attrs)
        | lid == location && isNothing (assetInvestigator attrs) && canAfford
        ]
      _ -> pure mempty
  getActions iid window (JazzMulligan attrs) = getActions iid window attrs

instance HasSet Trait env LocationId => HasModifiersFor env JazzMulligan where
  getModifiersFor (InvestigatorSource iid) (LocationTarget lid) (JazzMulligan attrs)
    | ownedBy attrs iid
    = do
      traits <- getSet lid
      pure [ toModifier attrs Blank | Miskatonic `member` traits ]
  getModifiersFor _ _ _ = pure []

instance (HasQueue env, HasModifiersFor env (), HasId LocationId env InvestigatorId) => RunMessage env JazzMulligan where
  runMessage msg a@(JazzMulligan attrs@Attrs {..}) = case msg of
    Revelation iid source | isSource attrs source -> do
      lid <- getId iid
      a <$ unshiftMessage (AttachAsset assetId (LocationTarget lid))
    UseCardAbility iid source _ 1 | isSource attrs source -> a <$ unshiftMessage
      (BeginSkillTest iid source (toTarget attrs) (Just Parley) SkillIntellect 3
      )
    PassedSkillTest iid _ source SkillTestInitiatorTarget{} _
      | isSource attrs source -> a
      <$ unshiftMessage (TakeControlOfAsset iid assetId)
    _ -> JazzMulligan <$> runMessage msg attrs
