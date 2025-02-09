from rest_framework.serializers import ModelSerializer, Serializer
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.validators import FileExtensionValidator
from django.utils.timezone import now
from django.contrib.auth import get_user_model

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):

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
    password = serializers.CharField(write_only=True, validators=[validate_password], required=False)
    confirm_password = serializers.CharField(write_only=True, required=False)
    username = serializers.CharField(read_only=True)
    created_at = serializers.DateTimeField(read_only=True)
    is_current_user = serializers.SerializerMethodField()
    followers_count = serializers.SerializerMethodField()
    following_count = serializers.SerializerMethodField()
    followers = serializers.SerializerMethodField()
    following = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'profile', 'birthday', 'bio', 'password', 'confirm_password',
            'username', 'created_at', 'is_current_user', 'followers_count', 'following_count', 'followers', 'following'
        ]

    def get_is_current_user(self, obj):
        request = self.context.get('request')
        return bool(request and request.user and request.user.id == obj.id)

    def get_followers_count(self, obj):
        return obj.get_followers().count() if obj.get_followers() else 0

    def get_following_count(self, obj):
        return obj.get_following().count() if obj.get_following() else 0

    def get_followers(self, obj):
        followers = obj.get_followers() or []
        return [{'id': f.id, 'username': f.username, 'profile': f.profile.url if f.profile else None} for f in followers]

    def get_following(self, obj):
        following = obj.get_following() or []
        return [{'id': f.id, 'username': f.username, 'profile': f.profile.url if f.profile else None} for f in following]

    def validate_birthday(self, value):
        if value > now().date():
            raise serializers.ValidationError("La date entrée n'est pas valide.")
        return value

    def validate(self, data):
        password = data.get("password")
        confirm_password = data.get("confirm_password")

        if password or confirm_password:
            if not password or not confirm_password:
                raise serializers.ValidationError({"password": "Les deux champs mot de passe sont requis."})
            if password != confirm_password:
                raise serializers.ValidationError({"password": "Les mots de passe ne correspondent pas."})
        return data

    def create(self, validated_data):
        validated_data.pop('confirm_password', None)
        profile = validated_data.pop('profile', None)
        birthday = validated_data.pop('birthday', None)
        bio = validated_data.pop('bio', None)

        user = User.objects.create_user(
            email=validated_data['email'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            password=validated_data['password']
        )

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