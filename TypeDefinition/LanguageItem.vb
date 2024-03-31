Imports System.ComponentModel
Imports System.Globalization

Public Class LanguageItem
    Implements INotifyPropertyChanged
    Public Event PropertyChanged(sender As Object, e As PropertyChangedEventArgs) Implements INotifyPropertyChanged.PropertyChanged
    Public Event SelectionChanged(sender As LanguageItem, e As SelectionChangedEventArgs)

    Class SelectionChangedEventArgs
        Inherits System.EventArgs

        Sub New()

        End Sub

    End Class

    Sub New()
        _Selected = False
        _Visible = True
        _DisplayName = ""
    End Sub

    Private Sub NotifyPropertyChanged(Optional propertyName As String = "")
        RaiseEvent PropertyChanged(Me, New PropertyChangedEventArgs(propertyName))
    End Sub

    Dim _CultureInfo As CultureInfo
    Dim _Selected, _Visible As Boolean
    Dim _DisplayName As String

    Public Property CultureInfo As CultureInfo
        Get
            Return _CultureInfo
        End Get
        Set(value As CultureInfo)
            _CultureInfo = value
            _DisplayName = _CultureInfo.DisplayName
            NotifyPropertyChanged("CultureInfo")
            NotifyPropertyChanged("DisplayName")
        End Set
    End Property

    Public ReadOnly Property DisplayName As String
        Get
            Return _DisplayName
        End Get
    End Property

    Public Property Selected As Boolean
        Get
            Return _Selected
        End Get
        Set(value As Boolean)
            _Selected = value
            RaiseEvent SelectionChanged(Me, New SelectionChangedEventArgs())
            NotifyPropertyChanged("Selected")
        End Set
    End Property

    Public Property Visible As Boolean
        Get
            Return _Visible
        End Get
        Set(value As Boolean)
            _Visible = value
            RaiseEvent SelectionChanged(Me, New SelectionChangedEventArgs())
            NotifyPropertyChanged("Visible")
        End Set
    End Property

End Class
