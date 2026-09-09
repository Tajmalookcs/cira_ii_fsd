from django import forms
from django.contrib.auth.forms import UserCreationForm

from .models import Designation, User

TEXT = {"class": "form-control"}
SELECT = {"class": "form-select"}

SHARED_FIELDS = ["username", "full_name", "designation", "role", "contact_no", "email", "is_active"]
SHARED_WIDGETS = {
    "username": forms.TextInput(attrs=TEXT),
    "full_name": forms.TextInput(attrs=TEXT),
    "designation": forms.Select(attrs=SELECT),
    "role": forms.Select(attrs=SELECT),
    "contact_no": forms.TextInput(attrs=TEXT),
    "email": forms.EmailInput(attrs=TEXT),
    "is_active": forms.CheckboxInput(attrs={"class": "form-check-input"}),
}


class DesignationChoiceMixin(forms.ModelForm):
    """Offer only designations that are still in use."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        field = self.fields.get("designation")
        if field is not None:
            field.queryset = Designation.objects.filter(is_active=True)
            field.empty_label = "-- Select Designation --"


class UserCreateForm(DesignationChoiceMixin, UserCreationForm):
    class Meta:
        model = User
        fields = SHARED_FIELDS
        widgets = SHARED_WIDGETS

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name in ("password1", "password2"):
            self.fields[name].widget.attrs.update(TEXT)


class UserUpdateForm(DesignationChoiceMixin):
    new_password = forms.CharField(
        label="Reset Password",
        required=False,
        widget=forms.PasswordInput(attrs={**TEXT, "autocomplete": "new-password"}),
        help_text="Leave blank to keep the current password.",
    )

    class Meta:
        model = User
        fields = SHARED_FIELDS
        widgets = SHARED_WIDGETS

    def save(self, commit=True):
        user = super().save(commit=False)
        password = self.cleaned_data.get("new_password")
        if password:
            user.set_password(password)
        if commit:
            user.save()
        return user
