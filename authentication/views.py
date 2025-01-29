from rest_framework.viewsets import ModelViewSet
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework import status, serializers
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.conf import settings
from django.contrib.auth import password_validation

from authentication.serializers import UserSerializer, ForgotPasswordSerializer, ResetPasswordSerializer
from authentication.models import User

class UserViewSet(ModelViewSet):

    serializer_class = UserSerializer

    def get_permissions(self):

        if self.action == 'create':
            permission_classes = [AllowAny]
        else:
            permission_classes = [IsAuthenticated]

        return [permission() for permission in permission_classes]

    def get_queryset(self):
        if self.request.user.is_superuser:  # Si l'utilisateur est admin, il voit tout
            return User.objects.all()
        return User.objects.filter(id=self.request.user.id)  # Sinon, uniquement ses propres données

class ForgotPasswordView(APIView):
    """
    Cette vue permet à un utilisateur de demander un lien de réinitialisation de mot de passe.
    """

    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                return Response({"detail": "Aucun utilisateur trouvé avec cet email."}, status=status.HTTP_400_BAD_REQUEST)

            # Générer un token de réinitialisation
            token = default_token_generator.make_token(user)
            reset_link = f"{request.scheme}://{request.get_host()}/reset-password/{user.pk}/{token}/"

            # Envoyer un email avec le lien de réinitialisation
            send_mail(
                'Réinitialisation du mot de passe',
                f"Voici votre lien de réinitialisation du mot de passe : {reset_link}",
                settings.DEFAULT_FROM_EMAIL,
                [email],
                fail_silently=False,
            )

            return Response({"detail": "Un email avec un lien de réinitialisation a été envoyé."}, status=status.HTTP_200_OK)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ResetPasswordView(APIView):
    """
    Cette vue permet à un utilisateur de réinitialiser son mot de passe.
    """

    def post(self, request, user_id, token):
        # Vérifier que le token est valide
        try:
            user = User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return Response({"detail": "Utilisateur non trouvé."}, status=status.HTTP_400_BAD_REQUEST)

        if not default_token_generator.check_token(user, token):
            return Response({"detail": "Le lien de réinitialisation a expiré ou est invalide."}, status=status.HTTP_400_BAD_REQUEST)

        serializer = ResetPasswordSerializer(data=request.data)
        if serializer.is_valid():
            new_password = serializer.validated_data['new_password']
            confirm_password = serializer.validated_data['confirm_password']

            if new_password != confirm_password:
                return Response({"detail": "Les mots de passe ne correspondent pas."}, status=status.HTTP_400_BAD_REQUEST)

            # Valider le mot de passe
            try:
                password_validation.validate_password(new_password, user)
            except serializers.ValidationError as e:
                return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

            # Réinitialiser le mot de passe
            user.set_password(new_password)
            user.save()

            return Response({"detail": "Le mot de passe a été réinitialisé avec succès."}, status=status.HTTP_200_OK)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
