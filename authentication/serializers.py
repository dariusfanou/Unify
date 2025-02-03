from rest_framework.serializers import ModelSerializer, Serializer
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.validators import FileExtensionValidator
from django.utils.timezone import now

from authentication.models import User

class UserSerializer(ModelSerializer):

    profile = serializers.ImageField(
        required=False,
        validators=[FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png'])]
    )
    birthday = serializers.DateField(
        required=False,
        format="%d/%m/%Y",
        input_formats=["%d/%m/%Y"],
    )
    bio = serializers.CharField(required=False, allow_blank=True, style={'base_template': 'textarea.html'})
    password = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'profile', 'birthday', 'bio', 'password', 'confirm_password']

    def validate_birthday(self, value):
        current_date = now().date()
        if value > current_date:
            raise serializers.ValidationError("La date entrée n'est pas valide")
        return value

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError({"password": "Les mots de passe ne correspondent pas."})
        return data

    def create(self, validated_data):
        validated_data.pop('confirm_password')  # On enlève 'confirm_password' avant de créer l'utilisateur
        profile = validated_data.pop('profile', None)
        birthday = validated_data.pop('birthday', None)
        bio = validated_data.pop('bio', None)
        user = User.objects.create_user(
            email=validated_data['email'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            password=validated_data['password']
        )

        if profile or birthday or bio:
            if profile:
                user.profile = profile
            if birthday:
                user.birthday = birthday
            if bio:
                user.bio = bio
            user.save()

        return user

class ForgotPasswordSerializer(Serializer):
    email = serializers.EmailField()

class ResetPasswordSerializer(Serializer):
    new_password = serializers.CharField(write_only=True, required=True)
    confirm_password = serializers.CharField(write_only=True, required=True)